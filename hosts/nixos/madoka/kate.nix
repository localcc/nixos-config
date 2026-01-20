{
  pkgs,
  ...
}:
{
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
      "opencode" = {
        path = "/home/kate/.local/share/opencode";
        devices = [ "kate_marble" ];
      };
    };

    home.packages = with pkgs; [
      opencode
    ];

    helix.enable = true;
    # do not remove
    home.stateVersion = "26.05";
  };
}
