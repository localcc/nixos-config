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

  additionalPackages = lib.filter (e: e != null) [
    (
      if (builtins.elem "ida" (builtins.attrNames inputs)) then
        inputs.ida.packages.${pkgs.stdenv.system}.default
      else
        null
    )
  ];
in
{
  imports = [
    ../../../common/nixos/syncthing.nix
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
    inputs.ghelper.nixosModules.default
    inputs.gpu-switcher.nixosModules.default
  ];

  security.sudo.wheelNeedsPassword = false;

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
  virtualisation = {
    containers.enable = true;
    podman = {
      enable = true;
      dockerCompat = true;
      defaultNetwork.settings.dns_enabled = true;
    };
  };

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
        ../../../common/home
        ../../../common/home/desktop.nix
        ../../../common/home/jj.nix
        ../../../common/home/git.nix
        ../../../common/home/helix.nix
        ../../../common/home/games.nix
        ../../../common/home/atuin.nix
        ../../../common/home/zellij.nix
        ../../../common/home/alacritty.nix
        ../../../common/home/syncthing.nix
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
        # (blender.override {
        #   cudaSupport = true;
        # })
        unityhub
      ] ++ additionalPackages;

      syncthing = {
        enable = true;
        tray = pkgs.syncthingtray;
        connectedDevices = [
          "kate_madoka"
          "cider"
        ];
      };
      services.syncthing.settings.folders = {
        "dev" = {
          path = "/home/kate/dev";
          devices = [
            "kate_madoka"
            "cider"
          ];
        };
        "opencode" = {
          path = "/home/kate/.local/share/opencode";
          devices = [ "kate_madoka" ];
        };
      };

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
      home.stateVersion = "26.05";
    };
  programs._1password-gui = {
    polkitPolicyOwners = [ "kate" ];
  };

  environment.pathsToLink = [
    "/share/applications"
    "/share/xdg-desktop-portal"
  ];

  # Boot
  boot.kernel.sysctl."fs.inotify.max_user_watches" = 2097152;
  # Minimal localmodconfig-derived config (see kernel.config); refresh with
  # `make olddefconfig && make localmodconfig` against the zen source.
  boot.kernelPackages = pkgs.linuxPackagesFor (
    pkgs.linuxManualConfig {
      inherit (pkgs.linuxPackages_zen.kernel) src version modDirVersion;
      configfile = ./kernel.config;
      allowImportFromDerivation = true;
      features = {
        efiBootStub = true;
        netfilterRPFilter = true;
        ia32Emulation = true;
      };
    }
  );
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

      WIFI_PWR_ON_BAT = "on";
      SOUND_POWER_SAVE_ON_BAT = 1;
      USB_AUTOSUSPEND = 1;
      NMI_WATCHDOG = 0;

      START_CHARGE_THRESH_BAT0 = 80;
      STOP_CHARGE_THRESH_BAT0 = 80;
    };
  };

  # Pause Syncthing folders while on battery and restore only the ones that were
  # running before unplugging (folders paused by hand stay paused).
  systemd.services.syncthing-power = {
    description = "Pause/resume Syncthing folders on AC/battery";
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      User = "kate";
      Group = "users";
      StateDirectory = "syncthing-power";
      Environment = [
        "HOME=/home/kate"
        "XDG_RUNTIME_DIR=/run/user/1000"
      ];
    };
    path = [ pkgs.syncthing ];
    script = ''
      state="$STATE_DIRECTORY/paused-on-battery"

      on_ac=1
      for d in /sys/class/power_supply/*/; do
        if [ "$(cat "$d/type" 2>/dev/null)" = "Mains" ]; then
          on_ac=$(cat "$d/online" 2>/dev/null)
        fi
      done

      folders=$(syncthing cli config folders list) || exit 0

      if [ "$on_ac" = "0" ]; then
        : > "$state"
        for id in $folders; do
          if [ "$(syncthing cli config folders "$id" paused get)" = "false" ]; then
            echo "$id" >> "$state"
          fi
          syncthing cli config folders "$id" paused set true >/dev/null
        done
      else
        [ -e "$state" ] || exit 0
        while read -r id; do
          if [ -n "$id" ]; then
            syncthing cli config folders "$id" paused set false >/dev/null
          fi
        done < "$state"
        rm -f "$state"
      fi
    '';
  };

  services.scx = {
    enable = true;
    scheduler = "scx_lavd";
  };

  # GPU
  services.xserver.videoDrivers = [
    "modesetting"
    "nvidia"
  ];

  hardware.graphics.enable = true;
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
      version = "615.78.08";
      sha256_64bit = "sha256-Pj9t3cLudnoIGFMAr3vjyyhuznZpjS3eNSRZl4LQf/4=";
      sha256_aarch64 = "sha256-UHYBE1AYHoGgMfD9AS/jX+S+N8eCDWUft6qolK9Eejc=";
      openSha256 = "sha256-HBINiOjL0ZJLIAJeNIBYHBnwgUXtNwPPtnFpAI1YwF4=";
      settingsSha256 = "sha256-inDRpG02sdDgHmlqgu/DsgK8OFdOt1fZIYyXdhlGC/c=";
      persistencedSha256 = "sha256-RzeR6Ldct6MUxjnXRyThdh5Y3jjMehTVg85MtwuWNX4=";
    };
  };

  services = {
    gpu-switcher = {
      enable = true;
      settings = {
        device_path = "0000:64:00.0";
        hotplug_type = "Asus";
      };
    };
    ghelper = {
      enable = true;
      user = "kate";
    };
  };

  # Keep the dGPU (endpoint 0000:64:00.0, behind port 0000:00:03.1) from ever
  # entering ASPM link states or runtime-suspending, so it doesn't fall off the
  # bus during VFIO passthrough. Every other PCIe link keeps ASPM/port-PM (TLP
  # still applies PCIE_ASPM_ON_BAT). Runs on hot-add too, since g-helper toggles
  # dgpu_disable at runtime.
  services.udev.extraRules =
    let
      dgpuDisablePm = pkgs.writeShellScript "dgpu-disable-pm" ''
        for s in l0s_aspm l1_aspm l1_1_aspm l1_2_aspm; do
          f="/sys/bus/pci/devices/$1/link/$s"
          [ -e "$f" ] && echo 0 > "$f"
        done
        f="/sys/bus/pci/devices/$1/power/control"
        [ -e "$f" ] && echo on > "$f"
        exit 0
      '';
    in
    ''
      ACTION=="add", SUBSYSTEM=="pci", KERNEL=="0000:64:00.0", RUN+="${dgpuDisablePm} %k"
      ACTION=="add", SUBSYSTEM=="pci", KERNEL=="0000:64:00.1", RUN+="${dgpuDisablePm} %k"
      ACTION=="add", SUBSYSTEM=="pci", KERNEL=="0000:00:03.1", RUN+="${dgpuDisablePm} %k"
      ACTION=="change", SUBSYSTEM=="power_supply", ENV{POWER_SUPPLY_TYPE}=="Mains", RUN+="${config.systemd.package}/bin/systemctl --no-block start syncthing-power.service"
    '';

  environment.systemPackages = with pkgs; [
    efibootmgr
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
