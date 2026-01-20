{
  pkgs,
  lib,
  config,
  ...
}:
let
  cfg = config.gnome;
in
{
  options = {
    gnome = {
      enable = lib.mkEnableOption "GNOME";
    };
  };

  config = lib.mkIf cfg.enable {
    # todo: when upgrading to 25.11, replace
    # https://wiki.nixos.org/wiki/GNOME
    services.xserver = {
      enable = true;
      displayManager.gdm.enable = true;
      desktopManager.gnome.enable = true;
    };

    # remove gnome tour and web browser
    environment.gnome.excludePackages = [
      pkgs.epiphany
      pkgs.gnome-tour
    ];

    programs.dconf.enable = true;
  };
}
