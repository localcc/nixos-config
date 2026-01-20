{
  config,
  lib,
  ...
}:
{
  hardware.enableRedistributableFirmware = lib.mkDefault true;

  boot.initrd.kernelModules = [
    "vfio_pci"
    "vfio"
    "vfio_iommu_type1"
  ];
  boot.initrd.availableKernelModules = [
    "nvme"
    "xhci_pci"
    "thunderbolt"
    "usb_storage"
    "usbhid"
    "sd_mod"
    "rtsx_pci_sdmmc"
    "k10temp"
  ];
  boot.supportedFilesystems = [ "ntfs" ];
  boot.extraModulePackages = [
    config.boot.kernelPackages.zenpower
  ];
  boot.kernelModules = [ "kvm-amd" "zenpower" "k10temp" ];
  boot.kernelParams = [
    "amd_iommu=on"
    "nvidia.NVreg_RegistryDwords=EnableBrightnessControl=1"
    # ASPM and PCIe port runtime-PM used to be disabled globally here
    # ("pcie_aspm=off" "pcie_port_pm=off") so the dGPU wouldn't fall off the
    # bus while passed through. That also killed power management on every
    # other link. Now scoped to the dGPU's port/endpoint via udev in
    # hosts/nixos/marble/default.nix.
  ];
  boot.extraModprobeConfig = ''
    options vfio-pci disable_vga=1 disable_idle_d3=1
  '';
  boot.kernelPatches = [
    {
      name = "dgpu-runtime-enable";
      patch = ./patches/asus-armoury-dgpu-runtime-enable.patch;
    }
  ];

  fileSystems = {
    "/" = {
      device = "/dev/mapper/cryptroot";
      fsType = "btrfs";
    };
    "/boot" = {
      device = "/dev/disk/by-uuid/3079-D48B";
      fsType = "vfat";
      options = [
        "fmask=0077"
        "dmask=0077"
      ];
    };
  };
  environment.etc.crypttab.text = ''
    cryptroot UUID=c80fb4d8-6618-4877-99da-7fc1ce4b4b9c none no-read-workqueue,no-write-workqueue
  '';

  swapDevices = [
    {
      device = "/var/lib/swapfile";
      size = 64 * 1024;
    }
  ];

  boot.initrd.luks.devices."cryptroot".device =
    "/dev/disk/by-uuid/c80fb4d8-6618-4877-99da-7fc1ce4b4b9c";

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
}
