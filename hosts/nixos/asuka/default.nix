{
  ...
}:
{
  imports = [
    ../plugsuit
    ./disks.nix
  ];

  # Network
  networking.hostId = "62165b6d";
  plugsuit.network = {
    interface = "eno1";
    ipv4 = {
      address = "192.168.0.27/24";
      gateway = "192.168.0.1";
    };
  };

  system.stateVersion = "26.05";
}
