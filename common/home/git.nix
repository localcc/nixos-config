{
  config,
  pkgs,
  lib,
  ...
}:
let
  cfg = config.git;

  smtp = lib.lists.optional (cfg.smtp != null) cfg.smtp;
in
{
  options = {
    git = {
      enable = lib.mkEnableOption "Enable git";
      smtp = lib.mkOption {
        type = lib.types.nullOr lib.types.path;
        description = "Smtp configuration";
      };
    };
  };

  config = lib.mkIf cfg.enable {

    programs.git = {
      enable = true;
      settings = {
        user = {
          name = "Kate";
          email = "work@localcc.cc";
        };
      };

      includes = (lib.map (x: { path = x; }) smtp);
    };
  };
}
