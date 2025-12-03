{
  pkgs,
  inputs,
  ...
}:
{
  imports = [
    # ./gnome.nix
    # ./niri.nix
    # ./greetd.nix
    # ./user.nix
    ./gdm.nix
    ./localization.nix
    ./network.nix
    ./splash.nix
    ./secureboot.nix
    ./sound.nix
  ];

  # boot
  boot.loader.timeout = 0;
  # boot.splash = {
  #   enable = lib.mkDefault true;
  #   themePackage = pkgs.plymouth-matrix-theme;
  #   theme = "matrix";
  # };
  boot.binfmt.preferStaticEmulators = true;
  boot.binfmt.emulatedSystems = [ "powerpc64-linux" ];

  services.fwupd.enable = true;

  # shebang support for scripts
  services.envfs.enable = true;

  # unpackaged executables
  programs.nix-ld.enable = true;

  services.tailscale.enable = true;
  services.mullvad-vpn = {
    enable = true;
    package = pkgs.mullvad-vpn;
  };

  programs._1password.enable = true;
  programs._1password-gui.enable = true;
  programs.localsend.enable = true;
  environment.systemPackages =
    with pkgs;
    let
      unstable = import inputs.nixpkgs-unstable { inherit system; };
    in
    [
      # basic dev
      gh
      git
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
      rust-bin.stable."1.90.0".default

      # apps
      telegram-desktop
      unstable.zed-editor
      discord
      # parsec-bin
      trayscale
      obsidian

      (microsoft-edge.override {
        commandLineArgs = [
          "--enable-features=TouchpadOverscrollHistoryNavigation,VaapiVideoDecodeLinuxGL,VaapiVideoEncoder,VaapiIgnoreDriverChecks,VaapiVideoDecoder,PlatformHEVCDecoderSupport,UseMultiPlaneFormatForHardwareVideo"
          "--disable-features=GlobalShortcutsPortal" # https://issues.chromium.org/issues/404298968
        ];
      })

      # shell
      wget
    ];
}
