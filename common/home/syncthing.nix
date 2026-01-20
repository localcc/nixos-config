{
  inputs,
  config,
  pkgs,
  lib,
  hostname,
  osConfig,
  ...
}:
let
  cfg = config.syncthing;

  devices = {
    "kate_marble" = {
      id = "UYS23D4-QE7CB5S-FVS6V24-QGJ453Q-7NABEUF-63NCUX7-ZRZH7X6-2DCQ5AK";
    };
    "kate_madoka" = {
      id = "JRQTBFV-AY24HCE-H7WG445-EK6SMMB-GKVJPXB-52SATZG-TSQM6IM-6RP2CQM";
    };
    "cider" = {
      id = "VU7PJFE-A7VPJUP-CM6NCHX-XVS3HJM-XFC4KSV-5EHTWAT-DMYKKHG-YPY24QH";
    };
  };

  selfName = "${config.home.username}_${hostname}";
  certId = "syncthing-${config.home.username}-${hostname}-cert";
  keyId = "syncthing-${config.home.username}-${hostname}-key";

in
{
  options = {
    syncthing = {
      enable = lib.mkEnableOption "Enable syncthing";
      tray = lib.mkOption {
        type = lib.types.nullOr lib.types.package;
        description = "Tray package";
        default = null;
      };
      connectedDevices = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        description = "Machines to connect to";
        default = [ ];
      };
    };
  };

  config = lib.mkIf cfg.enable (
    lib.mkMerge [
      {
        age.secrets."${certId}".file = (inputs.secrets + /syncthing/${selfName}_cert.age);
        age.secrets."${keyId}".file = (inputs.secrets + /syncthing/${selfName}_key.age);

        services.syncthing = {
          enable = true;
          cert = config.age.secrets."${certId}".path;
          key = config.age.secrets."${keyId}".path;

          package = pkgs.syncthing;
          settings.devices =
            (lib.filterAttrs (name: value: (lib.lists.elem name cfg.connectedDevices)))
              devices;
        };
      }
      (lib.mkIf (cfg.tray != null) {
        services.syncthing.tray = {
          enable = true;
          package = cfg.tray;
        };
      })
    ]
  );
}
