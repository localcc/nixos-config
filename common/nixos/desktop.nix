{
  pkgs,
  inputs,
  lib,
  config,
  ...
}:
let
  cfg = config.desktop;
in
{
  options = {
    desktop = {
      enable = lib.mkEnableOption "Desktop Deployment";
      multi-de = lib.mkEnableOption "Multi Desktop Environment deployment";
    };
  };

  config = lib.mkIf cfg.enable {
    boot.binfmt.preferStaticEmulators = true;
    boot.binfmt.emulatedSystems = [ "powerpc64-linux" ];

    services.tailscale.enable = true;
    services.mullvad-vpn = {
      enable = true;
      gui.enable = true;
    };
    
    services.usbmuxd.enable = true;

    services.logind.settings.Login.HandleLidSwitch = "suspend";

    programs._1password.enable = true;
    programs._1password-gui.enable = true;
    programs.localsend.enable = true;
    programs.obs-studio = {
      enable = true;
      enableVirtualCamera = true;
      package = pkgs.obs-studio.override { cudaSupport = true; };
    };
    programs.wireshark = {
      enable = true;
      package = pkgs.wireshark;
      dumpcap.enable = true;
    };

    fonts.fontDir.enable = true;
    services.flatpak.enable = true;

    environment.systemPackages =
      with pkgs;
      let
        unstable = import inputs.nixpkgs-unstable { inherit system; };
      in
      [
        discord
        trayscale
        telegram-desktop
        # gnu (ew)
        gnumake
        gcc15
        # ps3 dev
        qemu-user

        helium
        # guh drm
        microsoft-edge
      ];

    };
}
