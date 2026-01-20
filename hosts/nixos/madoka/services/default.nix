{
  config,
  ...
}:
{
  imports = [
    ./unifi.nix
    ./tailscale.nix
    ./media-server.nix
  ];

  # Runtime
  virtualisation.podman = {
    enable = true;
    autoPrune.enable = true;
    dockerCompat = true;
  };

  # Enable container name DNS for all Podman networks.
  networking.firewall.interfaces =
    let
      matchAll = if !config.networking.nftables.enable then "podman+" else "podman*";
    in
    {
      "${matchAll}".allowedUDPPorts = [ 53 ];
    };

  virtualisation.oci-containers.backend = "podman";

  compose.networks = {
    "tailnet" = {
      ipam = {
        subnet = "172.20.0.0/24";
        gateway = "172.20.0.1";
      };
    };
  };
}
