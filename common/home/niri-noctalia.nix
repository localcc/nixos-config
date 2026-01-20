{
  lib,
  config,
  inputs,
  pkgs,
  ...
}:
let
  cfg = config.niri;

  matugenSchemeType = "scheme-tonal-spot";

  noctalia =
    cmd:
    [
      "noctalia"
      "ipc"
      "call"
    ]
    ++ (pkgs.lib.splitString " " cmd);

  battery = if cfg.laptop then [ { id = "Battery"; } ] else [ ];
in
{
  imports = [
    inputs.matugen.nixosModules.default
    inputs.noctalia.homeModules.default
  ];

  options = {
    niri = {
      noctalia = lib.mkEnableOption "Enable Noctalia theming";
      laptop = lib.mkEnableOption "Enable laptop specific settings";

      wallpaper = lib.mkOption {
        type = lib.types.path;
        description = "Wallpaper to use";
      };
      pfp = lib.mkOption {
        type = lib.types.path;
        description = "Profile picture to use";
      };
    };
  };

  config = lib.mkIf cfg.noctalia {
    home.packages = with pkgs; [
      matugen
      # gsettings
      glib
      dconf
      gsettings-desktop-schemas
      # gtk
      nwg-look
      # qt config tool
      kdePackages.qt6ct

      # cursors
      rose-pine-cursor
    ];

    home.pointerCursor = {
      name = "BreezeX-RosePine-Linux";
      package = pkgs.rose-pine-cursor;

      gtk.enable = true;
      x11.enable = true;
      size = 32;
    };
    programs.niri.settings.cursor = {
      theme = "BreezeX-RosePine-Linux";
      size = 32;
    };

    home.sessionVariables = {
      QT_QPA_PLATFORMTHEME = "qt6ct";
    };

    niri.switch-events = {
      lid-close.action.spawn = noctalia "lockScreen lock";
    };

    niri.binds = {
      "Ctrl+Alt+Delete" = {
        hotkey-overlay.title = "Power menu";
        action.spawn = noctalia "sessionMenu toggle";
      };

      "Mod+D" = {
        hotkey-overlay.title = "Run an Application";
        action.spawn = noctalia "panel-toggle launcher";
      };

      "Mod+L" = {
        hotkey-overlay.title = "Lock the Screen";
        action.spawn = noctalia "session lock";
      };

      "XF86AudioRaiseVolume" = {
        allow-when-locked = true;
        action.spawn = noctalia "volume increase";
      };
      "XF86AudioLowerVolume" = {
        allow-when-locked = true;
        action.spawn = noctalia "volume decrease";
      };
      "XF86AudioMute" = {
        allow-when-locked = true;
        action.spawn = noctalia "volume muteOutput";
      };
      "XF86AudioMicMute" = {
        allow-when-locked = true;
        action.spawn = noctalia "volume muteInput";
      };
    };

    niri.layout = {
      focus-ring = {
        width = 1;
        active.color = "#${config.programs.matugen.theme.colors.primary.default.color}";
        inactive.color = "#${config.programs.matugen.theme.colors.surface.default.color}";
        urgent.color = "#${config.programs.matugen.theme.colors.error.default.color}";
      };

      border = {
        active.color = "#${config.programs.matugen.theme.colors.primary.default.color}";
        inactive.color = "#${config.programs.matugen.theme.colors.surface.default.color}";
        urgent.color = "#${config.programs.matugen.theme.colors.error.default.color}";
      };

      shadow = {
        color = "#${config.programs.matugen.theme.colors.shadow.default.color}70";
      };

      tab-indicator = {
        active.color = "#${config.programs.matugen.theme.colors.primary.default.color}";
        inactive.color = "#${config.programs.matugen.theme.colors.primary_container.default.color}";
        urgent.color = "#${config.programs.matugen.theme.colors.error.default.color}";
      };

      insert-hint = {
        display.color = "#${config.programs.matugen.theme.colors.primary.default.color}80";
      };
    };
    niri.animations = { };

    niri.spawn-at-startup = [
      { argv = [ "noctalia" ]; }
    ];

    programs.noctalia = {
      enable = true;
      systemd.enable = false;
      # settings = {
      #   general = {
      #     avatarImage = cfg.pfp;
      #   };
      #   colorSchemes = {
      #     darkMode = true;
      #     generateTemplatesForPredefined = true;
      #     matugenSchemeType = matugenSchemeType;
      #     predefinedScheme = "Noctalia (default)";
      #     useWallpaperColors = true;
      #   };
      #   location = {
      #     monthBeforeDay = false;
      #     name = "Prague, Czechia";
      #   };
      #   wallpaper = {
      #     enabled = true;
      #     setWallpaperOnAllMonitors = true;
      #     directory = cfg.wallpaper + "/../";
      #     fillMode = "crop";
      #   };
      #   appLauncher = {
      #     enableClipboardHistory = true;
      #     terminalCommand = "alacritty -e";
      #   };
      #   sessionMenu = {
      #     enableCountdown = true;
      #     countdownDuration = 5000;
      #   };
      #   controlCenter = {
      #     position = "close_to_bar_button";
      #     shortcuts = {
      #       left = [
      #         {
      #           id = "WiFi";
      #         }
      #         {
      #           id = "Bluetooth";
      #         }
      #         {
      #           id = "PowerProfile";
      #         }
      #         {
      #           id = "KeepAwake";
      #         }
      #       ];
      #       right = [ ];
      #     };
      #   };
      #   bar = {
      #     density = "compact";
      #     position = "right";
      #     backgroundOpacity = 0.5;
      #     widgets = {
      #       left = [
      #         {
      #           id = "ControlCenter";
      #           useDistroLogo = true;
      #         }
      #         {
      #           id = "NotificationHistory";
      #         }
      #         {
      #           id = "plugin:catwalk";
      #         }
      #       ];
      #       center = [
      #         {
      #           hideUnoccupied = false;
      #           id = "Workspace";
      #           labelMode = "none";
      #         }
      #       ];
      #       right = [
      #         {
      #           id = "Tray";
      #           drawerEnabled = false;
      #         }
      #         {
      #           id = "WiFi";
      #         }
      #         {
      #           id = "Bluetooth";
      #         }
      #       ]
      #       ++ battery
      #       ++ [
      #         {
      #           id = "KeyboardLayout";
      #           displayMode = "forceOpen";
      #         }
      #         {
      #           formatHorizontal = "HH:mm";
      #           formatVertical = "HH mm";
      #           id = "Clock";
      #           useMonospacedFont = true;
      #           usePrimaryColor = true;
      #         }
      #       ];
      #     };
      #   };
      #   templates = {
      #     gtk = true;
      #     qt = true;
      #     niri = true;
      #   };
      #   idle = {
      #     enabled = true;
      #     screenOffTimeout = 600;
      #     lockTimeout = 660;
      #     suspendTimeout = 1800;
      #     fadeDuration = 5;
      #   };
      # };
    };

    home.file.".cache/noctalia/wallpapers.json" = {
      text = builtins.toJSON {
        defaultWallpaper = cfg.wallpaper;
      };
    };

    # noctalia copies r--r--r-- for some reason
    # and fails to apply the wallpaper colors then
    home.activation.themeFiles = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      mkdir -p ${config.xdg.configHome}/gtk-4.0
      mkdir -p ${config.xdg.configHome}/gtk-3.0
      mkdir -p ${config.xdg.configHome}/qt5ct/colors
      mkdir -p ${config.xdg.configHome}/qt6ct/colors

      touch ${config.xdg.configHome}/gtk-4.0/gtk.css
      touch ${config.xdg.configHome}/gtk-3.0/gtk.css
      touch ${config.xdg.configHome}/qt5ct/colors/noctalia.conf
      touch ${config.xdg.configHome}/qt6ct/colors/noctalia.conf
    '';

    programs.matugen = {
      enable = true;
      wallpaper = cfg.wallpaper;
      type = matugenSchemeType;
    };

    programs.alacritty.settings.colors = {
      primary = {
        background = "#${config.programs.matugen.theme.colors.background.default.color}";
        foreground = "#${config.programs.matugen.theme.colors.on_surface.default.color}";
      };

      cursor = {
        text = "#${config.programs.matugen.theme.colors.on_surface.default.color}";
        cursor = "#${config.programs.matugen.theme.colors.on_surface_variant.default.color}";
      };

      search = {
        matches = {
          background = "#${config.programs.matugen.theme.colors.tertiary.default.color}";
          foreground = "#${config.programs.matugen.theme.colors.surface_variant.default.color}";
        };

        focused_match = {
          background = "#${config.programs.matugen.theme.colors.primary.default.color}";
          foreground = "#${config.programs.matugen.theme.colors.surface_variant.default.color}";
        };
      };

      footer_bar = {
        background = "#${config.programs.matugen.theme.colors.inverse_surface.default.color}";
        foreground = "#${config.programs.matugen.theme.colors.surface_variant.default.color}";
      };

      hints = {
        start = {
          background = "#${config.programs.matugen.theme.colors.secondary.default.color}";
          foreground = "#${config.programs.matugen.theme.colors.surface_variant.default.color}";
        };

        end = {
          background = "#${config.programs.matugen.theme.colors.secondary.default.color}";
          foreground = "#${config.programs.matugen.theme.colors.surface_variant.default.color}";
        };
      };

      selection = {
        text = "#${config.programs.matugen.theme.colors.background.default.color}";
        background = "#${config.programs.matugen.theme.colors.primary.default.color}";
      };

      normal = {
        black = "#181818";
        red = "#${config.programs.matugen.theme.colors.error.default.color}";
        green = "#${config.programs.matugen.theme.colors.primary.default.color}";
        yellow = "#${config.programs.matugen.theme.colors.inverse_primary.default.color}";
        blue = "#${config.programs.matugen.theme.colors.primary.default.color}";
        magenta = "#${config.programs.matugen.theme.colors.tertiary.default.color}";
        cyan = "#${config.programs.matugen.theme.colors.secondary.default.color}";
        white = "#bac2de";
      };

      bright = {
        black = "#585B70";
        red = "#F38BA8";
        green = "#A6E3A1";
        yellow = "#F9E2AF";
        blue = "#89B4FA";
        magenta = "#F5C2E7";
        cyan = "#94E2D5";
        white = "#A6ADC8";
      };

      dim = {
        black = "#45475A";
        red = "#F38BA8";
        green = "#A6E3A1";
        yellow = "#F9E2AF";
        blue = "#89B4FA";
        magenta = "#F5C2E7";
        cyan = "#94E2D5";
        white = "#BAC2DE";
      };
    };
  };
}
