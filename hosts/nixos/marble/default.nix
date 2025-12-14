args@{
  inputs,
  config,
  lib,
  pkgs,
  ...
}:
let
  vmdir = "${config.users.users.kate.home}/vms";
  isodir = "${vmdir}/isos";

  win11-vmdir = "${vmdir}/win11";
  win11-vmpart = "/dev/nvme0n1p3";

  vmdirs = [
    isodir
    win11-vmdir
  ];
in
{
  imports = [
    ./hardware-configuration.nix
    ./alsa.nix
    ./qemu.nix
    ../../../common/nixos/niri.nix
    (import ./vms/win11-vm.nix (
      args
      // {
        inherit isodir;
        vmdir = win11-vmdir;
        vmpart = win11-vmpart;
        video = "none";
        gpu-passthrough = true;
        installation = false;
      }
    ))
    inputs.chaotic.nixosModules.nyx-cache
    inputs.chaotic.nixosModules.nyx-overlay
    inputs.chaotic.nixosModules.nyx-registry
  ];

  gdm.enable = true;
  niri.enable = true;
  niri.exo = true;

  environment.sessionVariables = {
    __EGL_VENDOR_LIBRARY_FILENAMES = "${pkgs.mesa}/share/glvnd/egl_vendor.d/50_mesa.json";
    __GLX_VENDOR_LIBRARY_NAME = "mesa";
  };

  home-manager.users.kate =
    { lib, ... }:
    {
      imports = [
        ../../../common/home/niri.nix
        ../../../common/home/niri-exo.nix
      ];

      home.activation.vmdir = lib.hm.dag.entryAfter [ "writeBoundary" ] (
        builtins.concatStringsSep "\n" (builtins.map (dir: "mkdir -p ${dir}") vmdirs)
      );

      programs.git = {
        enable = true;
        settings = {
          user.name = "kate";
          user.email = "work@localcc.cc";

          user.signingkey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEHWfBIxvY4c0Rdava/cAEa3qGUOxMSt4Cu0Ap7RtSK7";
          gpg.format = "ssh";
          gpg.ssh.program = "${pkgs._1password-gui}/bin/op-ssh-sign";
          commit.gpgsign = true;
        };
      };

      home.packages = with pkgs; [
        slack
        virt-manager
      ];

      niri = {
        enable = true;
        exo = true;
        wallpaper = (inputs.self + /assets/wallpaper.webp);

        binds = {
          "F6".action.screenshot = { };
        };

        debug = {
          render-drm-device = "/dev/dri/renderD128";
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
  # boot.secureboot.enable = true;
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.kernelPackages = pkgs.linuxPackages_cachyos;

  # Network bridge
  # networking.useDHCP = true;
  networking.bridges = {
    br0 = {
      interfaces = [ ];
    };
  };
  networking.interfaces.br0.ipv4.addresses = [
    {
      address = "10.0.0.2";
      prefixLength = 24;
    }
  ];
  networking.interfaces.br0.useDHCP = true;
  # networking.interfaces.enp103s0f4u1u2.useDHCP = true;

  # GPU
  services.xserver.videoDrivers = [
    "modesetting"
    "nvidia"
  ];

  hardware.graphics.enable = true;
  hardware.graphics.extraPackages = [ pkgs.libva-vdpau-driver ];
  hardware.nvidia = {
    modesetting.enable = true;
    powerManagement.enable = true;
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
      patchesOpen = [
        (pkgs.fetchpatch {
          name = "get_dev_pagemap.patch";
          url = "https://github.com/NVIDIA/open-gpu-kernel-modules/commit/3e230516034d29e84ca023fe95e284af5cd5a065.patch";
          hash = "sha256-BhL4mtuY5W+eLofwhHVnZnVf0msDj7XBxskZi8e6/k8=";
        })
      ];
    };
  };

  services = {
    supergfxd.enable = true;
    asusd = {
      enable = true;
      enableUserService = true;
    };
    power-profiles-daemon.enable = true;
  };

  # Steam
  programs.steam = {
    enable = true;
    localNetworkGameTransfers.openFirewall = true;
  };

  environment.systemPackages = with pkgs; [
    nodejs_24
    lsof
    (pkgs.writeShellScriptBin "nvidia-offload" ''
      export __NV_PRIME_RENDER_OFFLOAD=1
      export __NV_PRIME_RENDER_OFFLOAD_PROVIDER=NVIDIA-G0
      export __GLX_VENDOR_LIBRARY_NAME=nvidia
      export __VK_LAYER_NV_optimus=NVIDIA_only
      exec "$@"
    '')
  ];

  # Security
  security.polkit.enable = true;

  # Do not remove
  system.stateVersion = "25.11";
}
