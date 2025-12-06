{
  pkgs,
  inputs,
  lib,
  config,
  ...
}:
let
  cfg = config.niri;

  exo = builtins.fetchGit {
    url = "https://github.com/localcc/Exo.git";
    rev = "197c4a9a41f8aea1033a4cc5294a673640921b20";
  };

  seedIgnis = ./ignis;
  mergedIgnis = pkgs.symlinkJoin {
    name = "merged-ignis-config";
    paths = [
      "${exo}/ignis"
      "${config.programs.matugen.theme.files}/.config/ignis"
      (pkgs.runCommand "ignis-preview-colors" { } ''
        mkdir -p $out/styles
        cp ${exo}/exodefaults/preview-colors.scss $out/styles/preview-colors.scss
      '')
    ];
  };
  ignisFiles = builtins.readDir mergedIgnis;

  matugenConfig = builtins.fromTOML (builtins.readFile "${exo}/matugen/config.toml");

  matugenTemplates = lib.mapAttrs (
    name: value:
    {
      input_path = "${exo}/matugen/${lib.removePrefix "~/.config/matugen" (lib.removePrefix "./" value.input_path)}";
      output_path = value.output_path;
    }
    // lib.optionalAttrs (value ? post_hook) {
      post_hook = value.post_hook;
    }
  ) matugenConfig.templates;

  setWallpaper = "${
    inputs.awww.packages.${pkgs.stdenv.hostPlatform.system}.awww
  }/bin/awww img --transition-fps 120 --transition-duration 0.5 --transition-type grow --transition-pos center \"${cfg.wallpaper}\"";
  multipleDisplaysWallpaper = pkgs.writeShellScript "multiple-displays-wallpaper.sh" ''
    last=""
    while :; do
        out=$(niri msg -j outputs | jq -r '
        . as $r
        | ["eDP-1","HDMI-A-1"]
        | map({ name: ., mod: ($r[.] != null), connect: ["Disconnect","Connect"][if $r[.] then 1 else 0 end] })
      ')
       [[ "$out" != "$last" ]] && ${setWallpaper} && last="$out" && sleep 10
    done
  '';
in
{
  imports = [
    inputs.matugen.nixosModules.default
    inputs.ignis.homeManagerModules.default
  ];

  options = {
    niri = {
      exo = lib.mkEnableOption "Enable Exo theming";

      wallpaper = lib.mkOption {
        type = lib.types.path;
        description = "Wallpaper to use";
      };
    };
  };

  config = lib.mkIf cfg.exo {
    home.packages = with pkgs; [
      jq # for wallpaper script

      inputs.ignis-gvc.packages.${system}.ignis-gvc
      inputs.awww.packages.${system}.awww
      gnome-bluetooth
      adw-gtk3
      dart-sass
      material-symbols
      gpu-screen-recorder
      slurp
    ];
    programs.hyprlock.enable = true;

    niri.binds = {
      "Mod+D" = {
        hotkey-overlay.title = "Run an Application";
        action.spawn = [
          "ignis"
          "open-window"
          "Launcher"
        ];
      };

      "Mod+L" = {
        hotkey-overlay.title = "Lock the Screen";
        action.spawn = "hyprlock";
      };

      "Mod+T" = {
        action.spawn = "rio";
      };

      "Ctrl+Alt+Delete" = {
        hotkey-overlay.title = "Quit";
        action.spawn = [
          "ignis"
          "open-window"
          "PowerMenu"
        ];
      };
    };

    niri.spawn-at-startup = [
      {
        argv = [
          "ignis"
          "init"
        ];
      }
      { argv = [ "awww-daemon" ]; }
      {
        sh = "sleep 1 && ${setWallpaper}";
      }
      {
        argv = [ "${multipleDisplaysWallpaper}" ];
      }
    ];

    niri.layout = {
      focus-ring = {
        width = 1;
        active.color = "#${config.programs.matugen.theme.colors.on_primary.default}";
      };

      insert-hint = {
        display.color = "#${config.programs.matugen.theme.colors.on_primary.default}66";
      };
    };

    niri.animations = {
      window-open.kind.spring = {
        damping-ratio = 1.0;
        stiffness = 700;
        epsilon = 0.0001;
      };
      window-close.kind.spring = {
        damping-ratio = 1.0;
        stiffness = 700;
        epsilon = 0.1;
      };
      window-resize.kind.spring = {
        damping-ratio = 1.0;
        stiffness = 800;
        epsilon = 0.001;
      };
      window-movement.kind.spring = {
        damping-ratio = 1.0;
        stiffness = 600;
        epsilon = 0.0001;
      };
      overview-open-close.kind.spring = {
        damping-ratio = 1.0;
        stiffness = 900;
        epsilon = 0.0001;
      };
      workspace-switch.kind.spring = {
        damping-ratio = 1.0;
        stiffness = 800;
        epsilon = 0.00001;
      };
      horizontal-view-movement.kind.spring = {
        damping-ratio = 1.0;
        stiffness = 700;
        epsilon = 0.0001;
      };
    };

    programs.ignis = {
      enable = true;

      addToPythonEnv = true;

      services = {
        bluetooth.enable = true;
        audio.enable = true;
        network.enable = true;
      };

      sass = {
        enable = true;
        useDartSass = true;
      };
    };

    programs.matugen = {
      enable = true;

      wallpaper = cfg.wallpaper;
      templates = matugenTemplates;
    };
    home.file =
      lib.mapAttrs' (
        name: value:
        let
          outputPath = lib.removePrefix "~/" value.output_path;
        in
        lib.nameValuePair outputPath {
          source = "${config.programs.matugen.theme.files}/${outputPath}";
        }
      ) (lib.filterAttrs (name: _: name != "ignis") matugenTemplates)
      // lib.mapAttrs' (
        name: type:
        lib.nameValuePair "${config.xdg.configHome}/ignis/${name}" {
          source = "${mergedIgnis}/${name}";
          recursive = true;
        }
      ) ignisFiles;

    home.activation.ignisUserSettings = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      if [ ! -f "${config.xdg.configHome}/ignis/user_settings.json" ]; then
        mkdir -p "${config.xdg.configHome}/ignis"
        cp "${seedIgnis}/user_settings.json" "${config.xdg.configHome}/ignis/user_settings.json"
        chmod u+w "${config.xdg.configHome}/ignis/user_settings.json"
      fi
    '';
    # home.activation.applyWallpaper = lib.hm.dag.entryAfter [ "linkGeneration" ] setWallpaper;
  };
}
