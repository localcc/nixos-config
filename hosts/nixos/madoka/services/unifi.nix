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

  networking.firewall = {
    allowedTCPPorts = [ 8443 ];
  };
}
