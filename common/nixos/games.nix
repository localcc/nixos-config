{
  inputs,
  lib,
  config,
  pkgs,
  ...
}:
let
  cfg = config.games;

  unstable = (
    import inputs.nixpkgs-unstable {
      system = pkgs.stdenv.system;
      config.allowUnfree = true;
    }
  );
in
{
  options = {
    games = {
      enable = lib.mkEnableOption "Games";
    };
  };

  config = lib.mkIf cfg.enable {
    # Steam
    programs.steam = {
      enable = true;
      localNetworkGameTransfers.openFirewall = true;
      # package = unstable.steam;
      # gamescopeSession.enable = true;
      package = unstable.steam.override {
        extraPkgs = pkgs: [
          pkgs.gamescope
        ];
      };
    };
    # programs.gamescope = {
    #   enable = true;
    #   package = unstable.gamescope;
    #   # capSysNice = true;
    # };
    services.ananicy = {
      enable = true;
      extraRules = [
        {
          name = "gamescope";
          nice = -20;
        }
      ];
    };
  };
}
