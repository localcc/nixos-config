{
  pkgs,
  lib,
  config,
  inputs,
  ...
}:
{
  imports = [
    inputs.home-manager.nixosModules.home-manager
    {
      home-manager.extraSpecialArgs = { inherit inputs; };
      home-manager.useGlobalPkgs = true;
      home-manager.useUserPackages = true;
      home-manager.backupFileExtension = "bak";
    }
  ];

  home-manager.users.kate = { lib, ... }: {
    imports = [
      ../../../common/home
      ../../../common/home/atuin.nix
      ../../../common/home/zellij.nix
      ../../../common/home/helix.nix
      ../../../common/home/syncthing.nix
    ];

    syncthing = {
      enable = true;
      connectedDevices = [ "kate_marble" "cider" ];
    };
    services.syncthing.settings.folders = {
      "dev" = {
        path = "/home/kate/dev";
        devices = [ "kate_marble" "cider" ];
      };
    };

    helix.enable = true;
    # do not remove
    home.stateVersion = "26.05";
  };
}
