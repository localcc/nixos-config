{
  pkgs,
  inputs,
  lib,
  config,
  ...
}:
let
  cfg = config.niri;
in
{
  options = {
    niri = {
      plain = lib.mkEnableOption "Plain niri with waybar";
    };
  };

  config = lib.mkIf cfg.plain {
    home.packages =
      with pkgs;
      let
        unstable = import inputs.nixpkgs-unstable { inherit system; };
      in
      [
        unstable.anyrun # runner
        swaynotificationcenter
        waybar
      ];
    programs.swaylock.enable = true;

    niri.spawn-at-startup = [
      { argv = [ "waybar" ]; }
    ];

    niri.binds = {
      "Mod+D" = {
        hotkey-overlay.title = "Run an Application";
        action.spawn = "anyrun";
      };

      "Super+L" = {
        hotkey-overlay.title = "Lock the Screen";
        action.spawn = "swaylock";
      };

      "Ctrl+Alt+Delete".action.quit = { };
    };
  };
}
