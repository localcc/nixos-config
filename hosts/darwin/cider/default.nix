{
  pkgs,
  inputs,
  ...
}:
{
  imports = [
    ./hardware-configuration.nix
  ];

  system.primaryUser = "kate";
  system.defaults.dock = {
    autohide = true;
    orientation = "bottom";

    showMissionControlGestureEnabled = true;
    showLaunchpadGestureEnabled = true;
    showDesktopGestureEnabled = true;

    magnification = true;
    tilesize = 46;
    largesize = 65;
    
    persistent-apps = [
      { app = "/System/Applications/Apps.app"; }
      { app = "/Applications/Helium.app"; }
      { app = "/Applications/Discord.app"; }
      { app = "/Applications/Telegram.app"; }
      { app = "/Users/kate/Applications/Home Manager Apps/iTerm2.app"; }
      { app = "/System/Applications/Music.app"; }
      { app = "/System/Applications/App Store.app"; }
      { app = "/System/Applications/System Settings.app"; }
      { app = "/System/Library/CoreServices/Applications/Feedback Assistant.app"; }
    ];

    persistent-others = [
      { folder = { path = "/Users/kate/Downloads"; showas = "fan"; arrangement = "date-added"; }; }
    ];
  };
  system.defaults.NSGlobalDomain."com.apple.trackpad.forceClick" = true;

  system.defaults.WindowManager.EnableTiledWindowMargins = false;
  system.defaults.finder = {
    AppleShowAllExtensions = true;
    AppleShowAllFiles = true;
    NewWindowTarget = "Home";
    ShowPathbar = true;
  };
  system.defaults.hitoolbox.AppleFnUsageType = "Change Input Source";

  system.defaults.menuExtraClock.Show24Hour = false;
  system.defaults.trackpad = {
    TrackpadFourFingerHorizSwipeGesture = 2;
    TrackpadFourFingerPinchGesture = 2;
    TrackpadFourFingerVertSwipeGesture = 2;
    TrackpadPinch = true;
    TrackpadRotate = true;
    TrackpadThreeFingerTapGesture = 0;
    TrackpadTwoFingerDoubleTapGesture = true;
    TrackpadTwoFingerFromRightEdgeSwipeGesture = 3;
  };

  system.startup.chime = true;

  security.pam.services.sudo_local.touchIdAuth = true;
  
  homebrew.enable = true;
  homebrew.masApps = {
    Telegram = 747648890;
  };

  home-manager.users.kate = { lib, ... }: {
    imports = [
      inputs.agenix.homeManagerModules.default
      ../../../common/home
      ../../../common/home/jj.nix
      ../../../common/home/git.nix
      ../../../common/home/helix.nix
      ../../../common/home/atuin.nix
      ../../../common/home/zellij.nix
      ../../../common/home/desktop.nix
      ../../../common/home/syncthing.nix
    ];

    jj.enable = true;
    git.enable = true;
    helix.enable = true;

    # nix-darwin sets PATH via /etc/zshenv, which nushell never reads
    programs.nushell.extraEnv = ''
      $env.PATH = ($env.PATH? | default [] | prepend [
        ($env.HOME | path join .nix-profile/bin)
        $"/etc/profiles/per-user/($env.USER? | default ($env.HOME | path split | last))/bin"
        /run/current-system/sw/bin
        /nix/var/nix/profiles/default/bin
      ] | uniq)
    '';

    syncthing = {
      enable = true;
      connectedDevices = [ "kate_madoka" "kate_marble" ];
    };
    services.syncthing.settings.folders = {
      "dev" = {
        path = "/Users/kate/devs";
        devices = [ "kate_madoka" "kate_marble" ];
      };
    };

    home.packages = with pkgs; [
      localsend
      tailscale-gui
      iterm2
      betterdisplay
    ];

    home.stateVersion = "26.05";
  };

  system.stateVersion = 7;
}
