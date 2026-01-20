{
  lib,
  config,
  pkgs,
  options,
  modulesPath,
  ...
}:
let
  cfg = config.compose;
  ociContainerOptions =
    (import (modulesPath + "/virtualisation/oci-containers.nix") {
      inherit
        options
        pkgs
        config
        lib
        ;
    }).options.virtualisation.oci-containers.containers.type;

  containerOptions =
    with lib;
    {
      options = {
        network = mkOption {
          type = types.nullOr types.str;
          default = null;
        };
      };
    };

  ipamOptions = with lib; {
    options = {
      subnet = mkOption {
        type = types.str;
        description = "Network subnet";
      };
      gateway = mkOption {
        type = types.str;
        description = "Gateway address inside of the network";
      };
    };
  };
  networkOptions = with lib; {
    options = {
      ipam = mkOption {
        type = types.nullOr (types.submodule ipamOptions);
        description = "IPAM configuration";
      };
    };
  };

  mapContainer =
    map: containerList:
    builtins.foldl' lib.recursiveUpdate { } (
      lib.map (
        { stackName, containers }: lib.mapAttrs' (name: value: map stackName name value) containers
      ) containerList
    );

  containerList = lib.mapAttrsToList (stackName: containers: {
    inherit stackName containers;
  }) cfg.stacks;
in
{
  options.compose = with lib; {
    stacks = mkOption {
      default = { };
      type = types.attrsOf (
        types.mergeTypes (types.attrsOf (types.submodule containerOptions)) ociContainerOptions
      );
    };
    networks = mkOption {
      default = { };
      type = types.attrsOf (types.submodule networkOptions);
    };
  };

  config = lib.mkMerge [
    (lib.mkIf (cfg.stacks != { }) (
      lib.mkMerge [
        {
          virtualisation.oci-containers.containers = mapContainer (
            stackName: name: value:
            let
              clean = builtins.removeAttrs value [
                "network"
                "serviceName"
              ];
              isContainerNetwork = value.network != null && (lib.strings.hasPrefix "container:" value.network);
            in
            {
              inherit name;
              value = lib.mkMerge [
                clean
                {
                  serviceName = "podman-${stackName}-${name}";
                  log-driver = "journald";
                }
                (lib.mkIf (value.network != null) {
                  extraOptions = [
                    "--network=${value.network}"
                  ];
                })
                (lib.mkIf (!isContainerNetwork) {
                  extraOptions = [
                    "--network-alias=${stackName}-${name}"
                  ];
                })
              ];
            }
          ) containerList;

          systemd.services = mapContainer (
            stackName: name: value:
            let
              isContainerNetwork = value.network != null && (lib.strings.hasPrefix "container:" value.network);
            in
            {
              name = "podman-${stackName}-${name}";
              value = lib.mkMerge [
                {
                  serviceConfig = {
                    Restart = lib.mkOverride 90 "always";
                  };
                  partOf = [
                    "podman-compose-${stackName}-root.target"
                  ];
                  wantedBy = [
                    "podman-compose-${stackName}-root.target"
                  ];
                }
                (lib.mkIf (!isContainerNetwork && value.network != null) {
                  after = [
                    "podman-network-${value.network}.service"
                  ];
                  requires = [
                    "podman-network-${value.network}.service"
                  ];
                })
              ];
            }
          ) containerList;
        }
        {
          systemd.services = lib.mapAttrs' (stackName: value: {
            name = "podman-network-${stackName}_default";
            value = {
              path = [ pkgs.podman ];
              serviceConfig = {
                Type = "oneshot";
                RemainAfterExit = true;
                ExecStop = "podman network rm -f ${stackName}_default";
              };
              script = ''
                podman network inspect ${stackName}_default || podman network create ${stackName}_default
              '';
              partOf = [ "podman-compose-${stackName}-root.target" ];
              wantedBy = [ "podman-compose-${stackName}-root.target" ];
            };
          }) cfg.stacks;

          systemd.targets = lib.mapAttrs' (stackName: value: {
            name = "podman-compose-${stackName}-root";
            value = {
              unitConfig = {
                Description = "Root target for the ${stackName} stack.";
              };
              wantedBy = [ "multi-user.target" ];
            };
          }) cfg.stacks;
        }
      ]
    ))
    (lib.mkIf (cfg.networks != { }) {
      systemd.services = lib.mapAttrs' (
        name: value:
        let
          networkConfig =
            if (value.ipam != null) then
              "--subnet=${value.ipam.subnet} --gateway=${value.ipam.gateway}"
            else
              "";
        in
        {
          name = "podman-network-${name}";
          value = {
            path = [ pkgs.podman ];
            serviceConfig = {
              Type = "oneshot";
              RemainAfterExit = true;
              ExecStop = "podman network rm -f ${name}";
            };
            script = ''
              podman network inspect ${name} || podman network create ${name} ${networkConfig}
            '';
          };
        }
      ) cfg.networks;
    })
  ];
}
