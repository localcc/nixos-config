{
  pkgs,
  lib,
  config,
  inputs,
  ...
}:
let
  cfg = config.kde;

  excludeAdditional =
    if config.desktop.multi-de then
      with pkgs.kdePackages;
      [
        kwallet
        kwallet-pam
        kwalletmanager
        plasma-integration
        kde-gtk-config
        libplasma
        drkonqi
        kauth
        gwenview
        okular
      ]
    else
      [ ];

  pkgs-master = import inputs.nixpkgs-master {
    system = pkgs.stdenv.system;
    config.allowUnfree = true;
  };

  kde-overlay = final: prev: {
    kdePackages = pkgs-master.kdePackages;
  };
in
{
  options = {
    kde = {
      enable = lib.mkEnableOption "KDE";
    };
  };

  config = lib.mkMerge [
    (lib.mkIf cfg.enable {
      nixpkgs.overlays = [
        kde-overlay
      ];

      services.desktopManager.plasma6.enable = true;
      security.pam.services = {
        login.kwallet.enable = lib.mkForce false;
        kde.kwallet.enable = lib.mkForce false;
      };
      environment.plasma6.excludePackages =
        with pkgs.kdePackages;
        [
          plasma-browser-integration
          plasma-workspace-wallpapers
          konsole
          elisa
          kate
          ktexteditor # provides elevated actions for kate
          khelpcenter
          dolphin
          baloo-widgets # baloo information in Dolphin
          dolphin-plugins
          # spectacle
          ffmpegthumbs
          krdp
        ]
        ++ excludeAdditional;
      environment.systemPackages = with pkgs; [
        kdePackages.oxygen
        kdePackages.oxygen-icons
        kdePackages.kclock
        nautilus
        polkit_gnome
      ];
      services.gvfs.enable = true;

      programs.kdeconnect = {
        enable = true;
      };

      services.displayManager.plasma-login-manager.enable = true;
      services.xserver = {
        enable = true;
      };

      programs.ssh.askPassword = lib.mkForce "";
    })
  ];
}
