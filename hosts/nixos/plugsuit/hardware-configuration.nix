{
  lib,
  ...
}:
{
  hardware.enableRedistributableFirmware = lib.mkDefault true;

  boot.initrd.availableKernelModules = [
    "xhci_pci"
    "ahci"
    "nvme"
    "usb_storage"
    "sd_mod"
  ];
  boot.kernelModules = [ "kvm-intel" ];

  fileSystems = {
    "/" = {
      device = "/dev/disk/by-partlabel/disk-main-root";
      fsType = "btrfs";
    };
    "/boot" = {
      device = "/dev/disk/by-partlabel/disk-main-ESP";
      fsType = "vfat";
      options = [
        "fmask=0077"
        "dmask=0077"
      ];
    };
  };
  swapDevices = [
    {
      device = "/var/lib/swapfile";
      size = 16 * 1024;
    }
  ];

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
}
