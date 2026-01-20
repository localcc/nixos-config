{
  config,
  lib,
  ...
}:
let
  cfg = config.helix;
in
{
  options = {
    helix = {
      enable = lib.mkEnableOption "Enable helix";
    };
  };

  config = lib.mkIf cfg.enable {
    programs.helix = {
      enable = true;
      settings = {
        editor.lsp.display-inlay-hints = true;
      };
      languages.language = [
        {
          name = "rust";
        }
      ];
    };
  };
}
