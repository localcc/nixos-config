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
    };
  };

  config = lib.mkIf cfg.enable {
    boot.binfmt.preferStaticEmulators = true;
    boot.binfmt.emulatedSystems = [ "powerpc64-linux" ];

    services.tailscale.enable = true;
    services.mullvad-vpn = {
      enable = true;
      package = pkgs.mullvad-vpn;
    };

    programs._1password.enable = true;
    programs._1password-gui.enable = true;
    programs.localsend.enable = true;
    programs.obs-studio = {
      enable = true;
      package = pkgs.obs-studio.override { cudaSupport = true; };
    };

    environment.systemPackages =
      with pkgs;
      let
        unstable = import inputs.nixpkgs-unstable { inherit system; };
      in
      [
        # basic dev
        gh
        neovim
        ripgrep
        cmake
        clang_20
        ninja
        python313
        meson

        # gnu (ew)
        gnumake
        gcc15

        # ps3 dev
        qemu-user

        # rust dev
        (rust-bin.stable."1.90.0".default.override {
          extensions = [ "rust-analyzer" "rust-src" ];
        })

        # apps
        telegram-desktop
        unstable.zed-editor
        discord
        # parsec-bin
        trayscale
        obsidian
        pavucontrol

        (microsoft-edge.override {
          commandLineArgs = [
            "--enable-features=TouchpadOverscrollHistoryNavigation,VaapiVideoDecodeLinuxGL,VaapiVideoEncoder,VaapiIgnoreDriverChecks,VaapiVideoDecoder,PlatformHEVCDecoderSupport,UseMultiPlaneFormatForHardwareVideo"
            "--disable-features=GlobalShortcutsPortal" # https://issues.chromium.org/issues/404298968
          ];
        })
      ];

    };
}
