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
  win11-vmpart = "/home/kate/vms/win11/win11.qcow2";

  vmdirs = [
    isodir
    win11-vmdir
  ];

  wave3FixScript = pkgs.writeShellScript "wave-3-fix" ''
    #!/bin/sh
    DEV_ID=$(${lib.getExe' pkgs.pipewire "pw-dump"} | ${lib.getExe' pkgs.jq "jq"} -r '
      .[]
      | select(.type=="PipeWire:Interface:Device")
      | select(.info.props["device.name"]=="alsa_card.usb-Elgato_Systems_Elgato_Wave_3_BS04K1A03612-00")
      | .id')

    ${lib.getExe' pkgs.wireplumber "wpctl"} set-profile "$DEV_ID" 2
    sleep 5
    ${lib.getExe' pkgs.wireplumber "wpctl"} set-profile "$DEV_ID" 5
  '';

  # jackWrap =
  #   drv:
  #   pkgs.symlinkJoin {
  #     name = "${drv.name}-jackwrapped";
  #     paths = [ drv ];
  #     buildInputs = [ pkgs.makeWrapper ];
  #     postBuild = ''
  #       ls "$out/bin"
  #       for b in "$out/bin/"*; do
  #         wrapProgram "$b" \
  #           --prefix LD_LIBRARY_PATH : "${pkgs.pipewire.jack}/lib"
  #       done
  #     '';
  #   };
  # carla-bridge = inputs.carla-win-bridge.packages.${pkgs.stdenv.system}.default;
  unstable = import inputs.nixpkgs-unstable {
    system = pkgs.stdenv.system;
    config.allowUnfree = true;
  };
in
{
  imports = [
    ./hardware-configuration.nix
    ./alsa.nix
    ./qemu.nix
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
    inputs.gpu-switcher.nixosModules.default
  ];
  kde.enable = true;
  desktop.enable = true;
  desktop.multi-de = false;
  wifi.enable = true;
  games.enable = true;
  embedded.enable = true;

  environment.sessionVariables = {
    __EGL_VENDOR_LIBRARY_FILENAMES = "${pkgs.mesa}/share/glvnd/egl_vendor.d/50_mesa.json";
    __GLX_VENDOR_LIBRARY_NAME = "mesa";
  };

  users.users.kate.extraGroups = [
    "plugdev"
    "dialout"
  ];

  networking.firewall.enable = false;
  blackwall.enable = true;
  blackwall.hooks = {
    input = {
      priority = "filter + 1";
      defaultVerdict = "drop";
    };
    forward = {
      priority = "filter + 1";
      defaultVerdict = "drop";
    };
  };

  blackwall.zones = {
    "uplink" = {
      interfaces = [
        "wlp99s0"
        "enp103s0f3u1u2"
      ];
    };
  };
  blackwall.rules.ssh = {
    type = "input";
    destinationPorts = [
      {
        port = 22;
        type = "tcp";
      }
    ];
    verdict = "accept";
  };
  blackwall.rules.lc-dev = {
    from = [ "uplink" ];
    destinationPorts = [
      {
        port = 1562;
        type = "tcp";
      }
    ];
    verdict = "accept";
  };
  blackwall.rules.satisfactory = {
    from = [ "uplink" ];
    destinationPorts = [
      {
        port = 7777;
        type = "tcp";
      }
      {
        port = 7777;
        type = "udp";
      }
      {
        port = 8888;
        type = "tcp";
      }
      {
        port = 8888;
        type = "udp";
      }
      {
        port = 3000;
        type = "tcp";
      }
    ];
    verdict = "accept";
  };

  age.secrets.pfp = {
    file = (inputs.secrets + /pfp.age);
    owner = "kate";
    mode = "600";
  };
  age.secrets.kate-git-smtp = {
    file = (inputs.secrets + /kate-git-smtp.age);
    owner = "kate";
    mode = "600";
  };
  
  home-manager.users.kate =
    { lib, ... }:
    {
      imports = [
        ../../../common/home/jj.nix
        ../../../common/home/git.nix
        ../../../common/home/helix.nix
        ../../../common/home/games.nix
        ../../../common/home/atuin.nix
        ../../../common/home/zellij.nix
        ./audio.nix
      ];

      home.activation.vmdir = lib.hm.dag.entryAfter [ "writeBoundary" ] (
        builtins.concatStringsSep "\n" (builtins.map (dir: "mkdir -p ${dir}") vmdirs)
      );

      jj.enable = true;
      git = {
        enable = true;
        smtp = config.age.secrets.kate-git-smtp.path;
      };
      helix.enable = true;
      home.packages = with pkgs; [
        unstable.devenv
        slack
        virt-manager
        inputs.colmena.packages.${system}.colmena
        (blender.override {
          cudaSupport = true;
        })
        unityhub
      ];

      xdg.portal = {
        enable = true;
        config.common.default = "kde";
        extraPortals = with pkgs; [
          kdePackages.xdg-desktop-portal-kde
        ];
      };

      xdg.configFile."autostart/wave-3-fix.desktop" = {
        text = ''
          [Desktop Entry]
          Type=Application
          Name=Elgato Wave: 3 input "stuck" fix
          Exec=${wave3FixScript}
          X-KDE-autostart-phase=2
          NoDisplay=true
        '';
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
  boot.kernelPackages = pkgs.linuxPackages_zen;
  boot.secureboot.enable = true;
  boot.splash = {
    enable = lib.mkDefault true;
    themePackage = (
      pkgs.adi1090x-plymouth-themes.override {
        selected_themes = [ "pixels" ];
      }
    );
    theme = "pixels";
  };
  services.scx.enable = true;
  # services.scx.scheduler = "scx_lavd";
  services.scx.scheduler = "scx_bpfland";

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

  # Bluetooth
  hardware.bluetooth.enable = true;

  # Battery
  services.upower.enable = true;
  services.power-profiles-daemon.enable = lib.mkForce false;
  services.tlp = {
    enable = true;
    settings = {
      CPU_SCALING_GOVERNOR_ON_AC = "performance";
      CPU_SCALING_GOVERNOR_ON_BAT = "powersave";

      CPU_ENERGY_PERF_POLICY_ON_BAT = "power";
      CPU_ENERGY_PERF_POLICY_ON_AC = "performance";

      RADEON_DPM_PERF_LEVEL_ON_AC = "auto";
      RADEON_DPM_PERF_LEVEL_ON_BAT = "low";

      PCIE_ASPM_ON_AC = "default";
      PCIE_ASPM_ON_BAT = "powersupersave";

      PLATFORM_PROFILE_ON_BAT = "quiet";

      CPU_BOOST_ON_AC = 1;
      CPU_BOOST_ON_BAT = 0;
    };
  };

  # GPU
  services.xserver.videoDrivers = [
    "modesetting"
    "nvidia"
  ];

  hardware.graphics.enable = true;
  hardware.graphics.extraPackages = [ pkgs.libva-vdpau-driver ];
  hardware.opengl.enable = true;
  hardware.graphics.extraPackages = [
    pkgs.libva-vdpau-driver
    pkgs.mesa.opencl
  ];
  hardware.nvidia = {
    modesetting.enable = true;
    powerManagement.enable = true;
    powerManagement.finegrained = false;
    dynamicBoost.enable = true;

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
      version = "610.43.02";
      sha256_64bit = "sha256-MDSgVLtM33dS/43CclZMsQVROAS/9TU4lFkBsWyndGM=";
      sha256_aarch64 = "sha256-isWTnokUA/dzWocFBLalnk4+O5gSExVjs3dVpdYTU88=";
      openSha256 = "sha256-hP5NVZZ4vGsACHLmUDKq4uckpd/kn1GxCSYnnJfAuBs=";
      settingsSha256 = "sha256-0YAhufRgjDW+uR+kjaTb154fibpcDw8QowfrucoZsKE=";
      persistencedSha256 = "sha256-Whgv9X+v2fRhzliOl2LzltY9v1SxDafFfv3IUPqj/hk=";
    };
  };

  services = {
    gpu-switcher = {
      enable = true;
      settings = {
        device_path = "0000:64:00.0";
      };
    };
    asusd = {
      enable = true;
      # enableUserService = true;
    };
  };


  environment.systemPackages = with pkgs; [
    gsettings-desktop-schemas
    inputs.nsight-graphics.packages.${system}.default
    nodejs_24
    lsof
    kdiskmark
    pciutils
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
