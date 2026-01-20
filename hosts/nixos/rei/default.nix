{
  ...
}:
{
  imports = [
    ../plugsuit
    ./disks.nix
  ];

  # Network
  networking.hostId = "31a3983c";
  plugsuit.network = {
    interface = "eno1";
    ipv4 = {
      address = "192.168.0.53/24";
      gateway = "192.168.0.1";
    };
  };

  system.stateVersion = "26.05";
}
