{
  config,
  lib,
  ...
}:
let
  cfg = config.helix;

  # rosePineTheme = pkgs.fetchFromGitHub {
  #   owner = "rose-pine";
  #   repo = "helix";
  #   rev = "2e40340c21e2f1f47e4b2b368471900a7bf5263b";
  #   hash = "sha256-HyPeq5eghE8eMswLmV/uN6CF8i943LYCkOBy4MNGxeU=";
  # };

  # themeFiles = builtins.listToAttrs (
  #   map
  #     (f: {
  #       name = lib.removeSuffix ".toml" f;
  #       value = builtins.readFile (rosePineTheme + "/${f}");
  #     })
  #     (
  #       builtins.filter (a: lib.hasSuffix ".toml" a) (
  #         lib.mapAttrsToList (k: v: k) (builtins.readDir rosePineTheme)
  #       )
  #     )
  # );
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
        theme = "horizon-dark-kate";
      };
      languages.language = [
        {
          name = "rust";
        }
      ];
      themes = {
        "horizon-dark-kate" = ''
          inherits = "horizon-dark"

          [palette]
          bg = "#191b23"
          light-gray = "#898ca8"
          gray = "#44485e"
        '';
      };
    };
  };
}
