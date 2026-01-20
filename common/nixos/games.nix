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

  # vkd3d-proton with Saancreed's nvapi-extras (D3D12 NV shader extensions, RTXMG)
  # and dxvk-nvapi d3d12-extras, injected into GE-Proton11-7.
  vkd3d-proton-src = pkgs.fetchFromGitHub {
    owner = "Saancreed";
    repo = "vkd3d-proton";
    rev = "d9df3232e62f7952ffb2bc95ea82e84cd2e2fbad";
    fetchSubmodules = true;
    hash = "sha256-rUsp/MS/pZETDB/4MYKRDYSgpi6zTMck8F2Ulo+D2QA=";
  };

  dxvk-nvapi-src = pkgs.fetchFromGitHub {
    owner = "jp7677";
    repo = "dxvk-nvapi";
    rev = "99f629d4e28cf5f6ef6d80716172b5f093ccc9e5";
    fetchSubmodules = true;
    hash = "sha256-Nq2Wip6982q16ZDdoVsGfM9fANT9GuaPn+diN34FCTc=";
  };

  mkVkd3dProton =
    cross:
    cross.stdenv.mkDerivation {
      pname = "vkd3d-proton-nvapi-extras";
      version = "3.1.0";
      src = vkd3d-proton-src;
      nativeBuildInputs = with pkgs; [
        meson
        ninja
        glslang
        wine
      ];
      buildInputs = [ cross.windows.pthreads ];
      mesonBuildType = "release";
    };

  mkDxvkNvapi =
    cross:
    cross.stdenv.mkDerivation {
      pname = "dxvk-nvapi-d3d12-extras";
      version = "0.9.2";
      src = dxvk-nvapi-src;
      nativeBuildInputs = with pkgs; [
        meson
        ninja
      ];
      buildInputs = [ cross.windows.pthreads ];
      mesonBuildType = "release";
      mesonFlags = [ "-Denable_tests=false" ];
    };

  proton-ge-nvapi = pkgs.stdenvNoCC.mkDerivation (finalAttrs: {
    pname = "proton-ge-nvapi";
    version = "GE-Proton11-7";

    src = pkgs.fetchzip {
      url = "https://github.com/GloriousEggroll/proton-ge-custom/releases/download/GE-Proton11-7/GE-Proton11-7-x86_64.tar.gz";
      hash = "sha256-ftW0vE45v2JsbaYqo/So0ZFfvdtakHX0XEXEE4TdxLk=";
    };

    dontUnpack = true;
    # Keep upstream Proton binaries/scripts untouched.
    dontFixup = true;

    outputs = [
      "out"
      "steamcompattool"
    ];

    installPhase = ''
      runHook preInstall
      echo "${finalAttrs.pname} should not be installed into environments. Use programs.steam.extraCompatPackages instead." > $out

      mkdir -p $steamcompattool
      cp -a --no-preserve=ownership ${finalAttrs.src}/. $steamcompattool/
      chmod -R u+w $steamcompattool

      cp -f ${mkVkd3dProton pkgs.pkgsCross.mingwW64}/bin/*.dll \
        $steamcompattool/files/lib/wine/vkd3d-proton/x86_64-windows/
      cp -f ${mkVkd3dProton pkgs.pkgsCross.mingw32}/bin/*.dll \
        $steamcompattool/files/lib/wine/vkd3d-proton/i386-windows/
      cp -f ${mkDxvkNvapi pkgs.pkgsCross.mingwW64}/bin/*.dll \
        $steamcompattool/files/lib/wine/nvapi/x86_64-windows/
      cp -f ${mkDxvkNvapi pkgs.pkgsCross.mingw32}/bin/*.dll \
        $steamcompattool/files/lib/wine/nvapi/i386-windows/

      substituteInPlace $steamcompattool/compatibilitytool.vdf \
        --replace-fail "GE-Proton11-7-x86_64" "GE-Proton11-7-nvapi"

      runHook postInstall
    '';

    meta = {
      description = "GE-Proton11-7 with vkd3d-proton nvapi-extras and dxvk-nvapi d3d12-extras";
      homepage = "https://github.com/GloriousEggroll/proton-ge-custom";
      license = lib.licenses.bsd3;
      platforms = [ "x86_64-linux" ];
    };
  });
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
      extraCompatPackages = with pkgs; [
        proton-cachyos-x86_64_v3
        proton-ge-nvapi
      ];
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
