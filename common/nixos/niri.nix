{
  pkgs,
  lib,
  config,
  ...
}:
let
  cfg = config.niri;
in
{
  options = {
    niri = {
      enable = lib.mkEnableOption "niri";
      exo = lib.mkEnableOption "Enable exo theming";
      plain = lib.mkEnableOption "Plain niri with waybar";
    };
  };

  config = lib.mkMerge [
    (lib.mkIf cfg.enable {
      services.gnome.gnome-keyring.enable = true;
      services.gvfs.enable = true;
      gdm.sessionPackages = [ pkgs.niri-unstable ];
    })
    (lib.mkIf cfg.exo {
      security.pam.services.hyprlock = { };
    })
    (lib.mkIf cfg.plain {
      security.pam.services.swaylock = { };
    })
  ];
}
