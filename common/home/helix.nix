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
        theme = "darkwash-kate";
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
        "darkwash-kate" = ''
          inherits = "darkwash"

          "variable.other.member" = "class"

          [palette]
          bg = "#15121a"
          comment = "#958eab"
        '';
        "darkwash" = ''
          # Darkwash — Helix port of the Visual Studio theme (Darkwash/Darkwash.vstheme)

          "comment"              = { fg = "comment", modifiers = ["italic"] }
          "keyword"              = "keyword"
          "keyword.directive"    = "preproc"
          "operator"             = "operator"
          "punctuation"          = "fg_dim"

          "string"               = "string"
          "string.special"       = "class"
          "constant"             = "class"        # literals orange
          "constant.numeric"     = "number"
          "constant.builtin"     = "class"

          "type"                 = "struct"       # Roslyn "struct name" green, the dominant type color
          "type.builtin"         = "keyword"      # VS colors uint/byte/etc. as keywords
          "type.enum"            = "enum"
          "type.enum.variant"    = "type_param"   # pink like VS "User Types", breaks up the green
          "constructor"          = "constant"     # pink

          "function"             = "function"
          "function.macro"       = "preproc"
          "function.builtin"     = "function"
          "function.method"      = "function"

          "variable"             = "variable"
          "variable.builtin"     = { fg = "keyword", modifiers = ["italic"] }
          "variable.parameter"   = "variable"
          "variable.other.member" = "fg"

          "label"                = "enum"
          "namespace"            = "interface"
          "special"              = "constant"

          "tag"                  = "tag"
          "attribute"            = "attribute"

          "markup.heading"       = { fg = "keyword", modifiers = ["bold"] }
          "markup.bold"          = { modifiers = ["bold"] }
          "markup.italic"        = { modifiers = ["italic"] }
          "markup.link.url"      = { fg = "string", modifiers = ["underlined"] }
          "markup.link.text"     = "attribute"
          "markup.quote"         = "comment"
          "markup.raw"           = "string"
          "markup.list"          = "operator"

          "diff.plus"            = "struct"
          "diff.minus"           = "interface"
          "diff.delta"           = "function"

          "ui.background"        = { bg = "bg" }
          "ui.text"              = "fg"
          "ui.text.focus"        = "fg"
          "ui.text.inactive"     = "fg_dim"
          "ui.text.info"         = "fg"

          "ui.cursor"            = { fg = "bg", bg = "fg" }
          "ui.cursor.primary"    = { fg = "bg", bg = "function" }
          "ui.cursor.match"      = { fg = "bg", bg = "attribute" }
          "ui.cursor.insert"     = { fg = "bg", bg = "struct" }
          "ui.cursor.select"     = { fg = "bg", bg = "type_param" }

          "ui.selection"         = { bg = "selection" }
          "ui.selection.primary" = { bg = "selection" }
          "ui.highlight"         = { bg = "inactive_sel" }
          "ui.cursorline.primary" = { bg = "bg_panel" }

          "ui.linenr"            = "line_nr"
          "ui.linenr.selected"   = "line_nr_sel"
          "ui.gutter"            = { bg = "bg_panel" }
          "ui.gutter.selected"   = { bg = "bg_panel" }

          "ui.statusline"           = { fg = "fg_dim", bg = "bg_statusline" }
          "ui.statusline.normal"    = { fg = "bg", bg = "accent", modifiers = ["bold"] }
          "ui.statusline.insert"    = { fg = "bg", bg = "struct", modifiers = ["bold"] }
          "ui.statusline.select"    = { fg = "bg", bg = "type_param", modifiers = ["bold"] }
          "ui.statusline.inactive"  = { fg = "line_nr", bg = "bg_statusline" }
          "ui.statusline.separator" = "border"

          "ui.popup"             = { fg = "fg", bg = "bg_panel" }
          "ui.popup.info"        = { fg = "fg", bg = "bg_panel" }
          "ui.window"            = { fg = "border" }
          "ui.help"              = { fg = "fg_dim", bg = "bg_panel" }
          "ui.menu"              = { fg = "fg", bg = "bg_panel" }
          "ui.menu.selected"     = { fg = "fg", bg = "accent" }
          "ui.menu.scroll"       = { fg = "line_nr", bg = "bg_panel" }

          "ui.virtual.whitespace"   = "whitespace"
          "ui.virtual.ruler"        = { bg = "bg_panel" }
          "ui.virtual.indent-guide" = "whitespace"
          "ui.virtual.inlay-hint"   = { fg = "fg_dimmer", bg = "bg_panel" }
          "ui.virtual.jump-label"   = { fg = "bg", bg = "function", modifiers = ["bold"] }

          "diagnostic.error"       = { underline = { color = "interface", style = "curl" } }
          "diagnostic.warning"     = { underline = { color = "function", style = "curl" } }
          "diagnostic.info"        = { underline = { color = "attribute", style = "curl" } }
          "diagnostic.hint"        = { underline = { color = "line_nr", style = "curl" } }
          "diagnostic.unnecessary" = { modifiers = ["dim"] }
          "diagnostic.deprecated"  = { modifiers = ["crossed_out"] }

          "error"   = "interface"
          "warning" = "function"
          "info"    = "attribute"
          "hint"    = "line_nr"

          [palette]
          bg            = "#0F0D13" # editor background
          bg_panel      = "#15131C" # tool windows, gutter, tabs
          bg_statusline = "#100F16" # status bar
          border        = "#241F31"
          fg            = "#EDEAF3" # plain text
          fg_dim        = "#C5C0D6" # output / secondary text
          fg_dimmer     = "#968db5"
          accent        = "#42257B" # VS accent fill
          selection     = "#4A1385"
          inactive_sel  = "#1B1824"
          line_nr       = "#443E56"
          line_nr_sel   = "#C5C0D6"
          whitespace    = "#2B2838"

          comment       = "#443F54"
          keyword       = "#A981E6"
          preproc       = "#C65FE3"
          operator      = "#CDC8D8"
          string        = "#D18BB2"
          number        = "#DF6AE7"
          constant      = "#E87AFF"

          class         = "#FFA171"
          struct        = "#4EC962"
          enum          = "#9ED9A7"
          interface     = "#FF779C" # delegate name
          type_param    = "#E88AF0" # user types
          function      = "#FFCF5C"
          variable      = "#DDB2EB" # locals / parameters

          tag           = "#AD8EEA" # XML/HTML names
          attribute     = "#B3A0D9"
        '';
      };
    };
  };
}
