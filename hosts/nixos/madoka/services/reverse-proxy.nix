{
  inputs,
  config,
  ...
}:
let
  dataDir = "/mnt/Storage/Docker/compose/reverse-proxy";

  corednsDir = ./reverse-proxy/coredns;
in
{
  age.secrets.madoka-caddy.file = (inputs.secrets + /reverse-proxy/caddy.age);
  age.secrets.madoka-cloudflare.file = (inputs.secrets + /reverse-proxy/cloudflare.age);
  age.secrets.madoka-tailscale.file = (inputs.secrets + /reverse-proxy/tailscale.age);

  compose.stacks = {
    "reverse-proxy" = {
      "cloudflare_tunnel" = {
        image = "cloudflare/cloudflared";
        environmentFiles = [
          config.age.secrets.madoka-cloudflare.path
        ];
        cmd = [
          "tunnel"
          "run"
        ];
        network."cloudflare_tunnel" = {
          ipv4-address = "172.24.0.2";
        };
      };
      "coredns" = {
        image = "coredns/coredns:1.13.1";
        environmentFiles = [
          config.age.secrets.madoka-caddy.path
        ];
        volumes = [
          "${corednsDir}:/etc/coredns:ro"
        ];
        cmd = [
          "-conf"
          "/etc/coredns/Corefile"
        ];
        dependsOn = [
          "tailscale"
        ];
        network."container:tailscale" = { };
      };
      "tailscale" = {
        image = "tailscale/tailscale:latest";
        # image = "nginx";
        environment = {
          "TS_ACCEPT_DNS" = "1";
          "TS_STATE_DIR" = "/var/lib/tailscale";
        };
        environmentFiles = [
          config.age.secrets.madoka-tailscale.path
        ];
        volumes = [
          "${dataDir}/data/tailscale:/var/lib/tailscale:rw"
        ];
        network."tailnet" = {
          ipv4-address = "172.20.0.2";
        };
        extraOptions = [
          "--cap-add=NET_ADMIN"
          "--device=/dev/net/tun:/dev/net/tun:rwm"
        ];
      };
    };
  };
}
