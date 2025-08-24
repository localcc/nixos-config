{
  pkgs, lib, config, inputs, ...
}:
let
  cfg = config.gnome;

  mkDockOption =
    default:
    lib.mkOption (
      with lib.types;
      {
        inherit default;
        type = listOf (strMatching "^.*\.desktop$");
        description = "GNOME dock favorite items";
      }
    );
in
{
  options = {
    gnome = {
      enable = lib.mkEnableOption "GNOME";
      dockItems = {
        left = mkDockOption [
          "microsoft-edge.desktop"
          "org.telegram.desktop.desktop"
          "discord.desktop"
        ];
        middle = mkDockOption [ ];
        right = mkDockOption [
          "dev.zed.Zed.desktop"
          "1password.desktop"
          "org.gnome.Console.desktop"
        ];
      };

      shellExtensions = lib.mkOption {
        type = lib.types.listOf lib.types.package;
        description = "List of packages containing GNOME Shell Extensions";
        default =
          with pkgs;
          with pkgs.gnomeExtensions;
          [
            appindicator
          ];
      };

      extraDconfOptions = lib.mkOption { type = lib.types.attrsOf lib.types.anything; };
    };
  };

  config = lib.mkIf cfg.enable {
    # todo: when upgrading to 25.11, replace
    # https://wiki.nixos.org/wiki/GNOME
    services.xserver = {
      enable = true;
      displayManager.gdm.enable = true;
      desktopManager.gnome.enable = true;
    };

    environment.systemPackages = cfg.shellExtensions;

    # remove gnome tour and web browser
    environment.gnome.excludePackages = [
      pkgs.epiphany
      pkgs.gnome-tour
    ];

    programs.dconf = {
      enable = true;
      profiles.user.databases = [
        {
          lockAll = true;
          settings = {
            # keyboard layouts
            "org/gnome/desktop/input-sources" = {
              show-all-sources = true;
              sources = [
                (lib.gvariant.mkTuple [ "xkb" "us" ])
                (lib.gvariant.mkTuple [ "xkb" "ru" ])
              ];
            };
            # time & date
            "org/gnome/desktop/datetime" = {
              automatic-timezone = true;
            };
            "org/gnome/system/location" = {
              enabled = true;
            };
            # appearance
            "org/gnome/desktop/interface" = {
              color-scheme = "prefer-dark";
              enable-hot-corners = false;
              gtk-enable-primary-paste = false;
            };
            "org/gnome/desktop/background" = {
              picture-uri-dark = "file://${inputs.self + /assets/wallpaper.webp}";
            };
            # dock & extensions
            "org/gnome/shell" = {
              favorite-apps = with cfg.dockItems; left ++ middle ++ right;
              enabled-extensions = map (p: p.extensionUuid) cfg.shellExtensions;
            };
          } // cfg.extraDconfOptions;
        }
      ];
    };
  };
}
