{
  pkgs, inputs, hostname, lib, ...
}:
{
  imports = [
    ./gnome.nix
    ./user.nix
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

  services.fwupd.enable = true;

  services.tailscale.enable = true;
  services.mullvad-vpn = {
    enable = true;
    package = pkgs.mullvad-vpn;
  };

  programs._1password.enable = true;
  programs._1password-gui.enable = true;
  environment.systemPackages =
    with pkgs;
    [
      # basic dev
      gh
      git
      neovim
      ripgrep

      # rust dev
      rust-bin.stable."1.88.0".default

      # apps
      telegram-desktop
      zed-editor
      discord
      parsec-bin
      trayscale

      (microsoft-edge.override {
        commandLineArgs = [
          "--enable-features=TouchpadOverscrollHistoryNavigation,Vulkan,VaapiVideoDecoder,VaapiIgnoreDriverChecks,DefaultANGLEVulkan,VulkanFromANGLE"
          "--disable-features=GlobalShortcutsPortal" # https://issues.chromium.org/issues/404298968
        ];
      })

      # shell
      wget
    ];
}
