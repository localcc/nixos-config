{
  lib,
  ...
}:
{
  hardware.enableRedistributableFirmware = lib.mkDefault true;

  boot.initrd.availableKernelModules = [
    "xhci_pci"
    "thunderbolt"
    "usb_storage"
    "usbhid"
  ];
  boot.kernelModules = [ "kvm-amd" ];
  boot.kernelParams = [
    "amd_iommu=on"
  ];

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
  
  #swapDevices = [
  #  {
  #    device = "/var/lib/swapfile";
  #    size = 64 * 1024;
  #  }
  #];

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
}
