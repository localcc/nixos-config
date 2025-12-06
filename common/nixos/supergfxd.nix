# Local supergfxd module - modified from nixpkgs
# Original: https://github.com/NixOS/nixpkgs/blob/7241bcbb4f099a66aafca120d37c65e8dda32717/nixos/modules/services/hardware/supergfxd.nix
{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:

let
  cfg = config.services.supergfxd;
  json = pkgs.formats.json { };
  # Use local supergfxctl from flake input instead of nixpkgs
  supergfxctl = inputs.supergfxctl.packages.${pkgs.system}.default;
in
{
  options = {
    services.supergfxd = {
      enable = lib.mkEnableOption "the supergfxd service";

      settings = lib.mkOption {
        type = lib.types.nullOr json.type;
        default = null;
        description = ''
          The content of /etc/supergfxd.conf.
          See <https://gitlab.com/asus-linux/supergfxctl/#config-options-etcsupergfxdconf>.
        '';
      };
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [ supergfxctl ];

    environment.etc."supergfxd.conf" = lib.mkIf (cfg.settings != null) {
      source = json.generate "supergfxd.conf" cfg.settings;
      mode = "0644";
    };

    services.dbus.enable = true;

    systemd.packages = [ supergfxctl ];
    systemd.services.supergfxd.wantedBy = [ "multi-user.target" ];
    systemd.services.supergfxd.path = [
      pkgs.kmod
      pkgs.pciutils
    ];

    services.dbus.packages = [ supergfxctl ];
    services.udev.packages = [ supergfxctl ];
  };

  meta.maintainers = [ ];
}
