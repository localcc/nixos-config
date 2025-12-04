{
  inputs,
  config,
  pkgs,
  ...
}:
{
  imports = [
    ./hardware-configuration.nix
    ./alsa.nix
    ../../../common/nixos/niri.nix
    inputs.chaotic.nixosModules.nyx-cache
    inputs.chaotic.nixosModules.nyx-overlay
    inputs.chaotic.nixosModules.nyx-registry
  ];

  gdm.enable = true;
  niri.enable = true;
  niri.exo = true;

  home-manager.users.kate = {
    imports = [
      ../../../common/home/niri.nix
      ../../../common/home/niri-exo.nix
    ];

    home.packages = with pkgs; [
      slack
    ];

    niri = {
      enable = true;
      exo = true;
      wallpaper = (inputs.self + /assets/wallpaper.webp);

      binds = {
        "F6".action.screenshot = { };
      };

      touchpad = {
        scroll-factor = 0.5;
      };

      outputs."DP-10" = {
        mode = {
          width = 2560;
          height = 1440;
          refresh = 143.981;
        };

        position = {
          x = 0;
          y = 0;
        };

        focus-at-startup = true;
      };

      outputs."DP-11" = {
        mode = {
          width = 2560;
          height = 1440;
          refresh = 143.981;
        };

        position = {
          x = 0;
          y = 0;
        };

        focus-at-startup = true;
      };

      outputs."eDP-1" = {
        position = {
          x = 450;
          y = 1440;
        };
      };
    };

    # do not remove
    home.stateVersion = "25.11";
  };
  programs._1password-gui = {
    polkitPolicyOwners = [ "kate" ];
  };

  environment.pathsToLink = [
    "/share/applications"
    "/share/xdg-desktop-portal"
  ];

  # Boot
  boot.secureboot.enable = true;
  boot.kernelPackages = pkgs.linuxPackages_6_17;

  # Network bridge
  # networking.useDHCP = true;
  # networking.bridges = {
  #   br0 = {
  #     interfaces = [ "enp103s0f3u1u2" ];
  #   };
  # };
  # networking.interfaces.br0.ipv4.addresses = [
  #   {
  #     address = "10.0.0.2";
  #     prefixLength = 24;
  #   }
  # ];
  # networking.interfaces.br0.useDHCP = true;
  # networking.interfaces.enp103s0f3u1u2.useDHCP = true;

  # GPU
  services.xserver.videoDrivers = [ "nvidia" ];

  hardware.graphics.enable = true;
  hardware.graphics.extraPackages = [ pkgs.libva-vdpau-driver ];
  hardware.nvidia = {
    modesetting.enable = true;
    powerManagement.enable = false;
    powerManagement.finegrained = false;

    # use nvidia opensource driver (not nouveau!!)
    open = true;
    nvidiaSettings = true;

    prime = {
      offload = {
        enable = true;
        enableOffloadCmd = true;
      };

      amdgpuBusId = "PCI:101:0:0";
      nvidiaBusId = "PCI:100:0:0";
    };

    package = config.boot.kernelPackages.nvidiaPackages.mkDriver {
      version = "580.95.05";
      sha256_64bit = "sha256-hJ7w746EK5gGss3p8RwTA9VPGpp2lGfk5dlhsv4Rgqc=";
      sha256_aarch64 = "sha256-zLRCbpiik2fGDa+d80wqV3ZV1U1b4lRjzNQJsLLlICk=";
      openSha256 = "sha256-RFwDGQOi9jVngVONCOB5m/IYKZIeGEle7h0+0yGnBEI=";
      settingsSha256 = "sha256-F2wmUEaRrpR1Vz0TQSwVK4Fv13f3J9NJLtBe4UP2f14=";
      persistencedSha256 = "sha256-QCwxXQfG/Pa7jSTBB0xD3lsIofcerAWWAHKvWjWGQtg=";
    };
  };

  services = {
    supergfxd.enable = true;
    asusd = {
      enable = true;
      enableUserService = true;
    };
  };

  # Steam
  programs.steam = {
    enable = true;
    localNetworkGameTransfers.openFirewall = true;
  };

  environment.systemPackages = with pkgs; [
    nodejs_24
  ];

  # Security
  security.polkit.enable = true;

  # Do not remove
  system.stateVersion = "25.11";
}
