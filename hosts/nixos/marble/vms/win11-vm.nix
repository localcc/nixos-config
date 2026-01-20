{
  inputs,
  pkgs,
  vmdir,
  vmpart,
  isodir,
  video,
  gpu-passthrough,
  installation,
  lib,
  ...
}:
let
  nixvirt = inputs.NixVirt;

  vmName = "win11";
  memSizeKib = 50331648;

  cpuTopology = [
    [
      0
      12
    ] # P#0 Zen5 cores
    [
      1
      13
    ]
    [
      2
      14
    ]
    [
      3
      15
    ]
    [
      4
      16
    ] # P#1 Zen5c cores
    [
      5
      17
    ]
    [
      6
      18
    ]
    [
      7
      19
    ]
    [
      9
      21
    ]
    [
      11
      23
    ]
  ];
  emulatorSet = "10,22,8,20";

  vmIsolatedThreads = "${emulatorSet}";
  normalHostThreads = "0-23";

  vmGovernor = "performance";
  normalGovernor = "powersave";
  vmPowerProfile = "performance";
  normalPowerProfile = "power-saver";

  # todo: only set governor for cpus pinned to the vm
  setGovernor = governor: powerprofile: ''
    ## Set CPU governor to mode indicated by variable
    CPU_COUNT=0
    for file in /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor
    do
        echo "${governor}" > $file;
        echo "CPU $CPU_COUNT governor: ${governor}";
        let CPU_COUNT+=1
    done

    ## Set system power profile to performance
    # ${pkgs.power-profiles-daemon}/bin/powerprofilesctl set ${powerprofile}

    sleep 1
  '';

  isolateThreads = threads: ''
    ## Return CPU cores as per set variable
    systemctl set-property --runtime -- user.slice AllowedCPUs=${threads}
    systemctl set-property --runtime -- system.slice AllowedCPUs=${threads}
    systemctl set-property --runtime -- init.scope AllowedCPUs=${threads}

    sleep 1
  '';

  startScript = ''
    VM_MEMORY=${builtins.toString memSizeKib}
    ## Calculate number of hugepages to allocate from memory (in MB)
    HUGEPAGES="$(($VM_MEMORY/$(($(grep Hugepagesize /proc/meminfo | ${pkgs.gawk}/bin/awk '{print $2}')))))"
    ${lib.fileContents ./scripts/alloc_hugepages.sh}
    ${setGovernor vmGovernor vmPowerProfile}
    ${isolateThreads vmIsolatedThreads}
  '';

  stopScript = ''
    ${lib.fileContents ./scripts/free_hugepages.sh}
    ${setGovernor normalGovernor normalPowerProfile}
    ${isolateThreads normalHostThreads}
  '';

  hookScript = pkgs.writeShellScript "hook.sh" ''
    GUEST_NAME="''$1"
    OPERATION="''$2"
    PHASE="''$3"

    if [ "''$GUEST_NAME" = "${vmName}" ]; then
      if [ "''$OPERATION" = "prepare" ] && [ "''$PHASE" = "begin" ]; then
        ${startScript}
      elif [ "''$OPERATION" = "release" ] && [ "''$PHASE" = "end" ]; then
        ${stopScript}
      fi
    fi
  '';

  gpuDevices =
    if gpu-passthrough then
      [
        {
          mode = "subsystem";
          type = "pci";
          managed = true;
          source.address = {
            domain = hex "0x0000";
            bus = hex "0x64";
            slot = hex "0x00";
            function = hex "0x0";
          };
          rom.file = "${./5070ti-vbios.rom}";
          address = {
            type = "pci";
            domain = hex "0x0000";
            bus = hex "0x01";
            slot = hex "0x00";
            function = hex "0x0";
          };
        }
        {
          mode = "subsystem";
          type = "pci";
          managed = true;
          source.address = {
            domain = hex "0x0000";
            bus = hex "0x64";
            slot = hex "0x00";
            function = hex "0x1";
          };
          address = {
            type = "pci";
            domain = hex "0x0000";
            bus = hex "0x04";
            slot = hex "0x00";
            function = hex "0x0";
          };
        }
      ]
    else
      [ ];
  cdRoms =
    if installation then
      [
        (
          mkCdRom {
            source.file = "${isodir}/Win11.iso";
            dev = "sdb";
            unit = 1;
          }
          // {
            boot.order = 1;
          }
        )
        (mkCdRom {
          source.file = "${isodir}/virtio-win.iso";
          dev = "sdc";
          unit = 2;
        })
      ]
    else
      [ ];
  virtioInputs =
    if installation then
      [ ]
    else
      [

        {
          type = "mouse";
          bus = "virtio";
          address = {
            type = "pci";
            domain = hex "0x0000";
            bus = hex "0x06";
            slot = hex "0x00";
            function = hex "0x0";
          };
        }
        {
          type = "keyboard";
          bus = "virtio";
          address = {
            type = "pci";
            domain = hex "0x0000";
            bus = hex "0x07";
            slot = hex "0x00";
            function = hex "0x0";
          };
        }
      ];
  networkInterfaces =
    if installation then
      [ ]
    else
      [
        {
          type = "network";
          mac.address = "52:54:00:fb:0e:b0";
          source.network = "nat0";
          model.type = "virtio";
          address = {
            type = "pci";
            domain = hex "0x0000";
            bus = hex "0x05";
            slot = hex "0x00";
            function = hex "0x0";
          };
        }
      ];

  hex = num: (builtins.fromTOML "hex = ${num}").hex;

  mkCdRom =
    {
      source,
      dev,
      unit,
    }:
    {
      type = "file";
      device = "cdrom";
      driver = {
        name = "qemu";
        type = "raw";
      };
      inherit source;
      target = {
        inherit dev;
        bus = "sata";
      };
      readonly = true;
      addresss = {
        inherit unit;
        type = "drive";
        controller = 0;
        bus = 0;
        target = 0;
      };
    };

  mkPcieRootPort =
    {
      index,
      chassis,
      port,
      bus,
      slot,
      function,
    }:
    {
      inherit index;
      type = "pci";
      model = "pcie-root-port";
      target = {
        inherit chassis;
        port = port;
      };
      address = {
        type = "pci";
        domain = hex "0x0000";
        bus = bus;
        slot = slot;
        function = function;
      };
    };
in
{
  virtualisation.libvirtd.qemu.vhostUserPackages = [ pkgs.virtiofsd ];
  virtualisation.libvirtd.hooks = {
    qemu = {
      "${vmName}" = "${hookScript}";
    };
  };

  virtualisation.libvirt.connections."qemu:///session".domains = [
    {
      definition = nixvirt.lib.domain.writeXML {
        name = vmName;
        uuid = "b4310a94-8e41-4681-a7e6-0c4d8140c83a";
        type = "kvm";
        cpu = {
          mode = "host-passthrough";
          check = "none";
          migratable = false;
          topology = {
            sockets = 1;
            cores = builtins.length cpuTopology;
            threads = builtins.length (builtins.head cpuTopology);
          };
          cache.mode = "passthrough";
          feature = [
            {
              policy = "require";
              name = "topoext";
            }
          ];
        };
        vcpu = {
          placement = "static";
          count = builtins.length cpuTopology * builtins.length (builtins.head cpuTopology);
        };
        cputune = {
          vcpupin = lib.lists.imap0 (index: cpu: {
            vcpu = index;
            cpuset = builtins.toString cpu;
          }) (lib.lists.flatten cpuTopology);
          emulatorpin.cpuset = emulatorSet;
        };
        memory = {
          count = memSizeKib;
          unit = "KiB";
        };
        memoryBacking = {
          hugepages = { };
        };
        os = {
          type = "hvm";
          arch = "x86_64";
          machine = "q35";

          loader = {
            readonly = true;
            secure = true;
            type = "pflash";
            format = "raw";
            path = "${pkgs.OVMFFull.fd}/FV/OVMF_CODE.ms.fd";
          };
          nvram = {
            template = "${pkgs.OVMFFull.fd}/FV/OVMF_VARS.ms.fd";
            templateFormat = "raw";
            format = "raw";
            path = "${vmdir}/win11_VARS.fd";
          };
        };
        features = {
          acpi = { };
          apic = { };
          hyperv = {
            mode = "custom";
            relaxed.state = true;
            vapic.state = true;
            spinlocks = {
              state = true;
              retries = 8191;
            };
            vpindex.state = true;
            runtime.state = true;
            synic.state = true;
            stimer.state = true;
            frequencies.state = true;
            tlbflush.state = true;
            ipi.state = true;
            avic.state = true;
          };
          vmport.state = false;
          smm.state = true;
        };
        clock = {
          offset = "localtime";
          timer = [
            {
              name = "rtc";
              tickpolicy = "catchup";
            }
            {
              name = "pit";
              tickpolicy = "delay";
            }
            {
              name = "hpet";
              present = false;
            }
            {
              name = "hypervclock";
              present = true;
            }
          ];
        };
        on_poweroff = "destroy";
        on_reboot = "restart";
        on_crash = "destroy";
        pm = {
          suspend-to-mem.enabled = false;
          suspend-to-disk.enabled = false;
        };
        devices = {
          emulator = "${pkgs.qemu}/bin/qemu-system-x86_64";
          disk = [
            {
              type = "block";
              device = "disk";
              driver = {
                name = "qemu";
                type = "raw";
                cache = "none";
                discard = "unmap";
                detect-zeroes = "unmap";
                io = "io_uring";
              };
              source.dev = vmpart;
              target = {
                dev = "vda";
                bus = "virtio";
              };
              address = {
                type = "pci";
                controller = 0;
                bus = hex "0x09";
                target = 0;
                unit = 0;
              };
              boot.order = if installation then 2 else 1;
            }
          ]
          ++ cdRoms;
          tpm = {
            model = "tpm-crb";
            backend = {
              type = "emulator";
              version = "2.0";
            };
          };
          controller = [
            {
              type = "usb";
              index = 0;
              model = "qemu-xhci";
              ports = 15;
              address = {
                type = "pci";
                domain = hex "0x0000";
                bus = hex "0x02";
                slot = hex "0x00";
                function = hex "0x0";
              };
            }
            {
              type = "pci";
              index = 0;
              model = "pcie-root";
            }
            {
              type = "pci";
              index = 1;
              model = "pcie-root-port";
              target = {
                chassis = 1;
                port = hex "0x10";
              };
              address = {
                type = "pci";
                domain = hex "0x0000";
                bus = hex "0x00";
                slot = hex "0x02";
                function = hex "0x0";
                multifunction = true;
              };
            }
          ]
          ++ (builtins.genList (
            index:
            mkPcieRootPort {
              index = index + 2; # index=2 and so on
              chassis = index + 2;
              port = (hex "0x10") + index + 1; # port = 0x11 and so on
              bus = hex "0x00";
              slot = hex "0x02";
              function = index + 1; # function=1 and so on
            }
          ) 6)
          ++ [
            {
              type = "pci";
              index = 9;
              model = "pcie-root-port";
              target = {
                chassis = 9;
                port = hex "0x18";
              };
              address = {
                type = "pci";
                domain = hex "0x0000";
                bus = hex "0x00";
                slot = hex "0x03";
                function = hex "0x0";
                multifunction = true;
              };
            }
          ]
          ++ (builtins.genList (
            index:
            mkPcieRootPort {
              index = index + 10; # index = 10 and so on
              chassis = index + 10;
              port = (hex "0x10") + index + 9; # port = 0x19 and so on
              bus = hex "0x00";
              slot = hex "0x03";
              function = index + 1; # function = 1 and so on
            }
          ) 5)
          ++ [
            {
              type = "scsi";
              index = 0;
              model = "virtio-scsi";
              driver = {
                iothread = 1;
                queues = 8;
              };
              address = {
                type = "pci";
                domain = hex "0x0000";
                bus = hex "0x03";
                slot = hex "0x00";
                function = hex "0x0";
              };
            }
          ];
          interface = networkInterfaces;
          input = virtioInputs ++ [
            {
              type = "mouse";
              bus = "ps2";
            }
            {
              type = "keyboard";
              bus = "ps2";
            }
          ];
          graphics = {
            type = "spice";
            autoport = true;
            listen.type = "address";
            image.compression = false;
            gl.enable = false;
          };
          sound = {
            model = "ich9";
            audio.id = 1;
            address = {
              type = "pci";
              domain = hex "0x0000";
              bus = hex "0x00";
              slot = hex "0x1b";
              function = hex "0x0";
            };
          };
          channel = [
            {
              type = "spicevmc";
              target = {
                type = "virtio";
                name = "com.redhat.spice.0";
              };
              address = {
                type = "virtio-serial";
                controller = 0;
                bus = 0;
                port = 1;
              };
            }
          ];
          audio = {
            id = 1;
            type = "none";
          };
          # gpu passthrough
          hostdev = gpuDevices;
          video = {
            model.type = video;
          };
          watchdog = {
            model = "itco";
            action = "reset";
          };
          memballoon.model = "none";
        };
        qemu-commandline = {
          arg = [
            { value = "-acpitable"; }
            { value = "file=${./acpi-battery.bin}"; }
            { value = "-fw_cfg"; }
            { value = "opt/ovmf/X-PciMmio64Mb,string=65536"; }
            { value = "-device"; }
            { value = "{'driver':'ivshmem-plain','id':'shmem0','memdev':'looking-glass'}"; }
            { value = "-object"; }
            {
              value = "{'qom-type':'memory-backend-file','id':'looking-glass','mem-path':'/dev/kvmfr0','size':134217728,'share':true}";
            }
          ];
        };
      };
    }
  ];
}
