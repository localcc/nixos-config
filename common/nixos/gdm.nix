{
  lib,
  config,
  ...
}:
let
  cfg = config.gdm;
in
{
  options = {
    gdm = {
      enable = lib.mkEnableOption "GDM";
      sessionPackages = lib.mkOption { type = lib.types.listOf lib.types.package; };
    };
  };

  config = lib.mkIf cfg.enable {
    services.xserver.enable = true;
    services.xserver.displayManager.gdm.enable = true;

    services.xserver.displayManager.sessionPackages = cfg.sessionPackages;
  };
}
