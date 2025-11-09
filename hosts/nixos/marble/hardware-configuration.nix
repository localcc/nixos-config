{
  config, lib, ...
}:
{
  hardware.enableRedistributableFirmware = lib.mkDefault true;

  boot.initrd.availableKernelModules = [
    "nvme"
    "xhci_pci"
    "thunderbolt"
    "usb_storage"
    "usbhid"
    "sd_mod"
    "rtsx_pci_sdmmc"
  ];
  boot.kernelModules = [ "kvm-amd" ];

  fileSystems = {
    "/" = {
      device = "/dev/mapper/cryptroot";
      fsType = "btrfs";
    };
    "/boot" = {
      device = "/dev/disk/by-uuid/E9A7-B96C";
      fsType = "vfat";
      options = [ "fmask=0077" "dmask=0077" ];
    };
  };

  swapDevices = [ {
    device = "/var/lib/swapfile";
    size = 64 * 1024;
  }];

  boot.initrd.luks.devices."cryptroot".device = "/dev/disk/by-uuid/6930c73b-81c7-446c-820b-5a754864e6b0";

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
}
