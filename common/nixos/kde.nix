{
  pkgs,
  lib,
  config,
  ...
}:
let
  cfg = config.kde;

  excludeAdditional = if config.desktop.multi-de then with pkgs.kdePackages; [
    kwallet
    kwallet-pam
    kwalletmanager
    plasma-integration
    kde-gtk-config
    libplasma
    drkonqi
    kauth
  ] else [ ];
in
{
  options = {
    kde = {
      enable = lib.mkEnableOption "KDE";
    };
  };

  config = lib.mkIf cfg.enable {
    services.desktopManager.plasma6.enable = true;
    security.pam.services = {
      login.kwallet.enable = lib.mkForce false;
      kde.kwallet.enable = lib.mkForce false;
    };
    environment.plasma6.excludePackages = with pkgs.kdePackages; [
      aurorae
      plasma-browser-integration
      plasma-workspace-wallpapers
      konsole
      (lib.getBin qttools) # Expose qdbus in PATH
      ark
      elisa
      gwenview
      okular
      kate
      ktexteditor # provides elevated actions for kate
      khelpcenter
      dolphin
      baloo-widgets # baloo information in Dolphin
      dolphin-plugins
      spectacle
      ffmpegthumbs
      krdp
    ] ++ excludeAdditional;

    services.xserver = {
      enable = true;
      displayManager.gdm.enable = true;
    };

    programs.ssh.askPassword = lib.mkForce "";
  };
}
