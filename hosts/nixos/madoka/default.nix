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
    ./services
    ./hardware-configuration.nix
  ];

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
  fileSystems."/mnt/Storage/Services" = {
    device = "Storage/Services";
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
      interfaces = [ "enp5s0" ];
    };
    "uplink-local" = {
      parents = [ "uplink" ];
      ipv4Addresses = [ "192.168.0.0/24" ];
    };
    "tailscale" = {
      interfaces = [ "tailscale0" ];
    };
    "podman" = {
      interfaces = [ "podman*" ];
    };
    "local" = {
      parents = [
        "uplink-local"
        "tailscale"
      ];
    };
  };

  blackwall.rules.ssh = {
    type = "input";
    # from = [ "local" ];
    destinationPorts = [ { port = 22; type = "tcp"; } ];
    verdict = "accept";
  };

  environment.systemPackages = with pkgs; [
    helix
  ];

  # Security
  security.polkit.enable = true;
  security.sudo.wheelNeedsPassword = false;

  system.stateVersion = "25.11";
}
