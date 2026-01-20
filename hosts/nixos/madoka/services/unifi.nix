{
  inputs,
  ...
}:
{
  disabledModules = [
    "services/networking/unifi.nix"
  ];

  imports = [
    "${inputs.nixpkgs-fork}/nixos/modules/services/networking/unifi.nix"
  ];

  services.unifi = {
    enable = true;
    openFirewall = true;
    dataDir = "/mnt/Storage/Services/unifi";
  };
  blackwall.rules."unifi" = {
    type = "input";
    from = [ "uplink-local" ];
    destinationPorts = [
      { port = 8080; type = "tcp"; }
      { port = 8880; type = "tcp"; }
      { port = 8843; type = "tcp"; }
      { port = 8443; type = "tcp"; }
      { port = 6789; type = "tcp"; }
      { port = 3478; type = "udp"; }
      { port = 10001; type = "udp"; }
    ];
    verdict = "accept";
  };
}
