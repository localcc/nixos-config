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
    };
  };

  config = lib.mkIf cfg.enable {
    services.gnome.gnome-keyring.enable = true;
    security.pam.services.swaylock = { };
    gdm.sessionPackages = [ pkgs.niri-unstable ];
  };
}
