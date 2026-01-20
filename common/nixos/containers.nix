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

  containerNetworkOptions = with lib; {
    options = {
      ipv4-address = mkOption {
        type = types.nullOr types.str;
        description = "ipv4 address within the network";
        default = null;
      };
      ipv6-address = mkOption {
        type = types.nullOr types.str;
        description = "ipv6 address within the network";
        default = null;
      };
    };
  };

  containerHealthCheckOptions = with lib; {
    options = {
      test = mkOption {
        type = types.str;
        description = "Command to run for healthcheck";
      };
      interval = mkOption {
        type = types.nullOr types.str;
        description = "Healthcheck interval";
        default = null;
      };
      timeout = mkOption {
        type = types.nullOr types.str;
        description = "Healthcheck timeout";
        default = null;
      };
      retries = mkOption {
        type = types.nullOr types.int;
        description = "Maximum number of failed healthchecks";
        default = null;
      };
      start-period = mkOption {
        type = types.nullOr types.str;
        description = "Period between container starting in which healthcheck failures will be ignored";
        default = null;
      };
    };
  };

  containerOptions = with lib; {
    options = {
      network = mkOption {
        type = types.attrsOf (types.submodule containerNetworkOptions);
        default = { };
      };
      healthcheck = mkOption {
        type = types.nullOr (types.submodule containerHealthCheckOptions);
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
      isV6 = mkOption {
        type = types.bool;
        description = "Is the network ipv6";
        default = false;
      };
    };
  };
  networkOptions = with lib; {
    options = {
      ipam = mkOption {
        type = types.nullOr (types.submodule ipamOptions);
        description = "IPAM configuration";
        default = null;
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
          blackwall.zones."podman" = {
            interfaces = [ "podman*" ];
          };
          blackwall.rules."podman-dns" = {
            type = "input";
            from = [ "podman" ];
            protocols = [
              "tcp"
              "udp"
            ];
            destinationPorts = [ 53 ];
            verdict = "accept";
          };
          blackwall.rules."podman-fwd" = {
            type = "forward";
            from = [ "podman" ];
            requiredStates = [
              "established"
              "related"
            ];
            verdict = "accept";
          };
          blackwall.rules."podman-fwd-1" = {
            type = "forward";
            to = [ "podman" ];
            verdict = "accept";
          };
        }
        {
          virtualisation.oci-containers.containers = mapContainer (
            stackName: name: value:
            let
              clean = builtins.removeAttrs value [
                "network"
                "healthcheck"
                "serviceName"
              ];
              containerNetwork = lib.findFirst (net: lib.strings.hasPrefix "container" net) null (
                builtins.attrNames value.network
              );
              hasContainerNetwork = containerNetwork != null;
              networks = lib.attrValues (
                lib.mapAttrs (
                  name: value:
                  let
                    ipv4Options = lib.lists.optional (value.ipv4-address != null) "ip=${value.ipv4-address}";
                    ipv6Options = lib.lists.optional (value.ipv6-address != null) "ip=${value.ipv6-address}";

                    networkOptions = lib.strings.intersperse "," (ipv4Options ++ ipv6Options);
                    networkArg = lib.concatStringsSep ":" ([ name ] ++ networkOptions);
                  in
                  "--network=${networkArg}"
                ) value.network
              );

              mkHealthcheckOption =
                option:
                (lib.mkIf (value.healthcheck.${option} != null) {
                  extraOptions = [
                    "--health-${option}=${value.healthcheck.${option}}"
                  ];
                });
            in
            {
              inherit name;
              value = lib.mkMerge [
                clean
                {
                  serviceName = "podman-${stackName}-${name}";
                  log-driver = "journald";
                }
                {
                  extraOptions = networks;
                }
                (lib.mkIf (!hasContainerNetwork) {
                  extraOptions = [
                    "--network-alias=${name}"
                  ];
                })
                (lib.mkIf (value.healthcheck != null) (
                  lib.mkMerge [
                    {
                      extraOptions = [
                        "--health-cmd=${value.healthcheck.test}"
                      ];
                    }
                    (lib.mkIf (value.healthcheck.retries != null) {
                      extraOptions = [
                        "--health-retries=${toString value.healthcheck.retries}"
                      ];
                    })
                    (mkHealthcheckOption "interval")
                    (mkHealthcheckOption "timeout")
                    (mkHealthcheckOption "start-period")
                  ]
                ))
              ];
            }
          ) containerList;

          systemd.services = mapContainer (
            stackName: name: value:
            let
              containerNetwork = lib.findFirst (net: lib.strings.hasPrefix "container" net) null (
                builtins.attrNames value.network
              );
              hasContainerNetwork = containerNetwork != null;
              dependentNetworks = lib.map (name: "podman-network-${name}.service") (
                builtins.attrNames value.network
              );
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
                (lib.mkIf (!hasContainerNetwork && value.network != null) {
                  after = dependentNetworks;
                  requires = dependentNetworks;
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
      # todo: maybe do something for ipam null? { };
      blackwall =
        let
          ipamNetworks = lib.filterAttrs (name: value: value.ipam != null) cfg.networks;
          ipamNetworkNames = lib.mapAttrsToList (name: value: "podman-network-${name}") ipamNetworks;
        in
        {
          zones = lib.mapAttrs' (name: value: {
            name = "podman-network-${name}";
            value = lib.mkMerge [
              (lib.mkIf (!value.ipam.isV6) {
                ipv4Addresses = [ "${value.ipam.subnet}" ];
              })
              (lib.mkIf (value.ipam.isV6) {
                ipv6Addresses = [ "${value.ipam.subnet}" ];
              })
            ];
          }) ipamNetworks;

          rules."podman-networks-dns" = {
            type = "input";
            from = ipamNetworkNames;
            protocols = [
              "tcp"
              "udp"
            ];
            destinationPorts = [ 53 ];
            verdict = "accept";
          };
          rules."podman-networks-fwd" = {
            type = "forward";
            from = ipamNetworkNames;
            requiredStates = [
              "established"
              "related"
            ];
            verdict = "accept";
          };
          rules."podman-networks-fwd-1" = {
            type = "forward";
            to = ipamNetworkNames;
            verdict = "accept";
          };
        };
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
