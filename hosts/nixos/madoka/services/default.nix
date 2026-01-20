{
  inputs,
  ...
}:
{
  imports = [
    ./unifi.nix
    ./tailscale.nix
    ./media-server.nix
    ./reverse-proxy.nix
    ./pocket-id.nix
    ./immich.nix
    ./forgejo.nix
    ./harmonia.nix
    ./autossh.nix
    ./ddns-client.nix
    ./hrt-scraper.nix
    ./oauth2-proxy
    inputs.private-services.nixosModules.madoka
  ];

  # Runtime
  virtualisation.podman = {
    enable = true;
    autoPrune.enable = true;
    dockerCompat = true;
  };
  virtualisation.oci-containers.backend = "podman";

  blackwall.rules.fwd-dnat = {
    type = "forward";
    text = ''
      ct status dnat accept
      ct state new iifname "podman*" accept
    '';
  };

  compose.networks = {
    "tailnet" = {
      ipam = {
        subnet = "172.20.0.0/24";
        gateway = "172.20.0.1";
      };
    };
    "cloudflare_tunnel" = {
      ipam = {
        subnet = "172.24.0.0/24";
        gateway = "172.24.0.1";
      };
    };
    "lan" = {
      additionalParams = [
        "--driver macvlan"
        "--interface-name enp5s0"
        "--subnet 192.168.0.0/24"
        "--gateway 192.168.0.1"
      ];
    };
  };
}
