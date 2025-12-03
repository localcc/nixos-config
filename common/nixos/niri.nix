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
    security.pam.services.swaylock = { };
    gdm.sessionPackages = [ pkgs.niri-unstable ];
  };
}
