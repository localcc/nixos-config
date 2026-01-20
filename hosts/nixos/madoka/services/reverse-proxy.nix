{
  inputs,
  config,
  ...
}:
let
  dataDir = "/mnt/Storage/Docker/compose/reverse-proxy";
in
{
  age.secrets.madoka-cloudflare.file = (
    inputs.secrets + /madoka-cloudflare.age
  );

  compose.stacks = {
    "reverse-proxy" = {
      "rp-caddy" = {
        image = "caddy:2-alpine";
        ports = [
          "80:80"
          "443:443"
        ];
        volumes = [
          "${dataDir}/config/caddy:/etc/caddy"
          "${dataDir}/configs/caddy:/config"
          "${dataDir}/data/caddy:/data"
          "${dataDir}/certs:/certs"
        ];
        dependsOn = [
          "tailscale"
        ];
        network."tailnet" = {};
        extraOptions = [
          "--cap-add=NET_ADMIN"
          "--dns=172.20.0.2"
        ];
      };
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
    };
  };
}
