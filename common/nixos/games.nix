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
    environment.systemPackages = with pkgs; [
      protonup-ng
      inputs.gamescope-launcher.packages.${system}.default
    ];

    # Steam
    programs.steam = {
      enable = true;
      localNetworkGameTransfers.openFirewall = true;
      # package = unstable.steam;
      gamescopeSession.enable = true;
      # package = unstable.steam.override {
      #   extraPkgs = pkgs: [
      #     pkgs.gamescope
      #   ];
      # };
    };
    programs.gamemode.enable = true;
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

    environment.sessionVariables = {
      STEAM_EXTRA_COMPAT_TOOLS_PATHS = "\${HOME}/.steam/root/compatibilitytools.d";
    };
  };
}
