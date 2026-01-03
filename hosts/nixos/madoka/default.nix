{
  pkgs,
  lib,
  config,
  inputs,
  ...
}:
let
  zfsCompatibleKernelPackages = lib.filterAttrs (
    name: kernelPackages:
    (builtins.match "linux_[0-9]+_[0-9]+" name) != null
    && (builtins.tryEval kernelPackages).success
    && (!kernelPackages.${config.boot.zfs.package.kernelModuleAttribute}.meta.broken)
  ) pkgs.linuxKernel.packages;
  latestKernelPackage = lib.last (
    lib.sort (a: b: (lib.versionOlder a.kernel.version b.kernel.version)) (
      builtins.attrValues zfsCompatibleKernelPackages
    )
  );
in
{ 
  imports = [
    ./samba.nix
    ./podman.nix
    ./hardware-configuration.nix
  ];

  age.secrets.madoka-tailscale-key.file = (inputs.self + /secrets/madoka-tailscale-key.age);
  services.tailscale = {
    enable = true;
    authKeyFile = config.age.secrets.madoka-tailscale-key.path;
    useRoutingFeatures = "server";
  };

  # Boot
  boot.kernelPackages = latestKernelPackage;
  boot.supportedFilesystems = [ "zfs" ];
  #boot.secureboot.enable = true;
  boot.loader.systemd-boot.enable = true;

  # Zfs
  fileSystems."/mnt/Storage" = {
    device = "Storage";
    fsType = "zfs";
    options = [ "zfsutil" ];
  };
  fileSystems."/mnt/Storage/WitchHut" = {
    device = "Storage/WitchHut";
    fsType = "zfs";
    options = [ "zfsutil" ];
  };
  fileSystems."/mnt/Storage/WitchHut/Kate" = {
    device = "Storage/WitchHut/Kate";
    fsType = "zfs";
    options = [ "zfsutil" ];
  };
  fileSystems."/mnt/Storage/Docker" = {
    device = "Storage/Docker";
    fsType = "zfs";
    options = [ "zfsutil" ];
  };
  systemd.services.zfs-mount.enable = false;
  services.zfs.autoScrub.enable = true;
  networking.hostId = "f2dc1576";
  networking.networkmanager.ensureProfiles.profiles = {
    "Wired" = {
      connection = {
        type = "ethernet";
        id = "Wired";
        interface-name = "enp5s0";
        autoconnect = true;
      };
      ipv4 = {
        method = "manual";
        addresses = "192.168.0.16/24";
        gateway = "192.168.0.1";
      };
      ipv6.method = "auto";
    };
  };
    
  # Security
  security.polkit.enable = true;
  security.sudo.wheelNeedsPassword = false;

  system.stateVersion = "25.11";
}
