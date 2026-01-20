{
  pkgs,
  inputs,
  ...
}:
{
  disabledModules = [ "services/desktops/flatpak.nix" ];

  imports = [
    ./gnome.nix
    ./niri.nix
    ./gdm.nix
    ./localization.nix
    ./network.nix
    ./splash.nix
    ./secureboot.nix
    ./sound.nix
    ./desktop.nix
    ./containers.nix
    ./games.nix
    ./embedded.nix
    ./kde.nix # fuckass hdr
    ./flatpak
    inputs.blackwall.nixosModules.default
  ];

  nix.settings = {
    substituters = [
      "https://nix-community.cachix.org"
      "https://cache.nixos.org/"
      "https://cache.nixos-cuda.org"
    ];
    trusted-public-keys = [
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      "cache.nixos-cuda.org:74DUi4Ye579gUqzH4ziL9IyiJBlDpMRn9MBN8oNan9M="
    ];
  };

  # boot
  boot.loader.timeout = 0;
  # boot.splash = {
  #   enable = lib.mkDefault true;
  #   themePackage = pkgs.plymouth-matrix-theme;
  #   theme = "matrix";
  # };

  services.fwupd.enable = true;

  # shebang support for scripts
  services.envfs.enable = true;

  # unpackaged executables
  programs.nix-ld.enable = true;

  environment.systemPackages =
    with pkgs;
    [
      # basic dev
      git
      
      # shell
      wget
    ];
}
