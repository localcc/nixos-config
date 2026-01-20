{
  pkgs,
  inputs,
  ...
}:
{
  # Disable upstream supergfxd module so we can use our local one
  disabledModules = [ "services/hardware/supergfxd.nix" ];

  imports = [
    ./gnome.nix
    ./niri.nix
    ./gdm.nix
    ./localization.nix
    ./network.nix
    ./splash.nix
    ./secureboot.nix
    ./sound.nix
    ./supergfxd.nix
    ./desktop.nix
    ./containers.nix
    inputs.blackwall.nixosModules.default
  ];

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
