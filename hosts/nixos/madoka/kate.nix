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
      ../../../common/home/atuin.nix
      ../../../common/home/zellij.nix
      ../../../common/home/helix.nix
    ];

    helix.enable = true;
    # do not remove
    home.stateVersion = "26.05";
  };
}
