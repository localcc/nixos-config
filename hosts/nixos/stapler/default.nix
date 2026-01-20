{
  pkgs,
  inputs,
  ...
}:
{
  imports = [
    inputs.disko.nixosModules.disko
    ./hardware-configuration.nix
    ./disks.nix
  ];

  boot.kernelPackages = pkgs.linuxPackages_7_2;
  boot.loader.systemd-boot.enable = true;

  # Http server
  services.caddy = {
    enable = true;
    extraConfig = ''
      cache.madoka.dev {
        reverse_proxy localhost:5000
      }
    '';
  };

  # Autossh setup
  users.users.kate.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJMha8Kn02O7wqz8clIXZ0r+9652hqYb2HyjerVDKrba"
  ];

  # Network
  networking.hostId = "1e5445c9";
  networking.networkmanager.ensureProfiles.profiles = {
    "Uplink" = {
      connection = {
        type = "ethernet";
        id = "Uplink";
        interface-name = "ens3";
        autoconnect = true;
      };
      ipv4.method = "auto";
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
      interfaces = [ "ens3" ];
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
  blackwall.rules.caddy = {
    type = "input";
    destinationPorts = [
      {
        port = 443;
        type = "tcp";
      }
      {
        port = 80;
        type = "tcp";
      }
    ];
    verdict = "accept";
  };
  blackwall.rules.madoka-autossh = {
    type = "input";
    destinationPorts = [
      {
        port = 5000;
        type = "tcp";
      }
      {
        port = 5000;
        type = "udp";
      }
    ];
    verdict = "accept";
  };

  # Security
  security.polkit.enable = true;
  security.sudo.wheelNeedsPassword = false;

  system.stateVersion = "26.05";
}
