{
  config,
  inputs,
  ...
}:
let
  dataDir = "/mnt/Storage/Docker/compose/pocket-id";
in
{
  age.secrets.madoka-pocket-id.file = (
    inputs.secrets + /madoka-pocket-id.age
  );
  
  compose.stacks = {
    "pocket-id" = {
      "pocket-id" = {
        image = "ghcr.io/pocket-id/pocket-id:v2";
        environment = {
          "PORT" = "1411";
          "TRUST_PROXY" = "true";
          "MAXMIND_LICENSE_KEY" = "";
          "PUID" = "1004";
          "PGID" = "1004";

          "APP_NAME" = "meow";
          "ACCENT_COLOR" = "#2D0835";
        };
        volumes = [
          "${dataDir}/data:/app/data"
        ];
        environmentFiles = [
          config.age.secrets.madoka-pocket-id.path
        ];
        healthcheck = {
          test = "/app/pocket-id healthcheck";
          interval = "1m30s";
          timeout = "5s";
          retries = 2;
          start-period = "10s";
        };
        network = {
          "cloudflare_tunnel" = {
            ipv4-address = "172.24.0.4";
          };
          "tailnet" = {};
        };
      };
    };
  };
}
