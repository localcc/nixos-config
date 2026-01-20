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
      protonup-qt
      xdotool
      xwininfo
      xxd
      yad
      inputs.gamescope-launcher.packages.${system}.default
    ];

    # Steam
    programs.steam = {
      enable = true;
      protontricks.enable = true;
      extraCompatPackages = with pkgs; [ proton-cachyos-x86_64_v3 ];
      package = pkgs.steam.override {
        extraPkgs =
          pkgs': with pkgs'; [
            gamemode # keep this
            
            meson
            pkg-config
            ninja
            wayland-scanner

            # For OpenVR
            cmake
            glslang

            # For `libdisplay-info`
            python3
            hwdata
            v4l-utils

            pipewire
            hwdata
            xorg.libX11
            xorg.libxcb
            wayland
            wayland-protocols
            vulkan-loader
            vulkan-headers
            vulkan-tools

            xorg.libXcomposite
            xorg.libXcursor
            xorg.libXdamage
            xorg.libXext
            xorg.libXi
            xorg.libXmu
            xorg.libXrender
            xorg.libXres
            xorg.libXtst
            xorg.libXxf86vm
            libavif
            libdrm
            libei
            SDL2
            libdecor
            libinput
            libxkbcommon
            gbenchmark
            pixman
            libcap
            lcms
            luajit

          ];
      };
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
    # programs.gamescope.package = unstable.gamescope;
    # programs.gamescope = {
    #   enable = true;
    #   package = unstable.gamescope;
    #   # capSysNice = true;
    # };

    environment.sessionVariables = {
      STEAM_EXTRA_COMPAT_TOOLS_PATHS = "\${HOME}/.steam/root/compatibilitytools.d";
    };
  };
}
