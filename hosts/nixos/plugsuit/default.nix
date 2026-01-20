{
  pkgs,
  inputs,
  config,
  lib,
  ...
}:
let
  cfg = config.plugsuit;

  linkOptions = with lib; {
    options = {
      address = mkOption {
        type = types.str;
        description = "IP address";
      };
      gateway = mkOption {
        type = types.str;
        description = "Gateway address";
      };
    };
  };

  networkOptions = with lib; {
    options = {
      interface = mkOption {
        type = types.str;
        description = "Main network interface";
      };
      ipv4 = mkOption {
        type = types.submodule linkOptions;
        description = "IPv4 settings";
      };
    };
  };
in
{
  options = {
    plugsuit = {
      network = lib.mkOption {
        type = lib.types.submodule networkOptions;
        description = "Network settings";
      };
      secureboot = lib.mkOption {
        type = lib.types.bool;
        description = "Enable secureboot";
        default = true;
      };
    };
  };

  imports = [
    inputs.disko.nixosModules.disko
    ./hardware-configuration.nix
  ];

  config = (
    lib.mkMerge [
      (lib.mkIf cfg.secureboot {
        boot.secureboot.enable = true;
      })
      (lib.mkIf (!cfg.secureboot) {
        boot.loader.systemd-boot.enable = true;
      })
      {
        boot.kernelPackages = pkgs.linuxPackages_7_2;

        # Network
        networking.networkmanager.ensureProfiles.profiles = {
          "Uplink" = {
            connection = {
              type = "ethernet";
              id = "Uplink";
              interface-name = cfg.network.interface;
              autoconnect = true;
            };
            ipv4 = {
              method = "manual";
              addresses = cfg.network.ipv4.address;
              gateway = cfg.network.ipv4.gateway;
            };
            ipv6.method = "auto";
          };
        };

        networking.firewall.enable = false;
        blackwall.enable = true;

        blackwall.hooks = {
          input = {
            priority = "filter + 1";
            defaultVerdict = "drop";
          };
          forward = {
            priority = "filter + 1";
            defaultVerdict = "drop";
          };
        };

        blackwall.zones = {
          "uplink" = {
            interfaces = [ cfg.network.interface ];
          };
        };
        blackwall.rules.ssh = {
          type = "input";
          destinationPorts = [
            {
              port = 22;
              type = "tcp";
            }
          ];
          verdict = "accept";
        };

        # Security
        security.polkit.enable = true;
        security.sudo.wheelNeedsPassword = false;
      }
    ]
  );
}
