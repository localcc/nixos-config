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
    services.displayManager.gdm.enable = true;

    services.displayManager.sessionPackages = cfg.sessionPackages;
  };
}
