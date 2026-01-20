{
  inputs,
  pkgs,
  lib,
  config,
  ...
}:
let
  dataDir = "/mnt/Storage/Docker/compose/media-server";
  mediaServerDir = "/mnt/Storage/WitchHut/media-server";
  torrentDir = "/mnt/Storage/WitchHut/torrents";
  timeZone = "Europe/Amsterdam";

  caddyDir = ./media-server/caddy;
in
lib.mkMerge [
  {
    age.secrets.madoka-mediaserver-caddy.file = (inputs.secrets + /reverse-proxy/caddy.age);
    age.secrets.madoka-mediaserver-gluetun.file = (inputs.secrets + /mediaserver/gluetun.age);

    compose.stacks = {
      "mediaserver" = {
        "GlueTun-VPN" = {
          image = "qmcgaw/gluetun";
          environment = {
            "TZ" = timeZone;
          };
          environmentFiles = [
            config.age.secrets.madoka-mediaserver-gluetun.path
          ];
          volumes = [
            "${dataDir}/gluetun:/tmp/gluetun:rw"
          ];
          ports = [
            "8081:8081/tcp"
            "51820:51820/tcp"
            "51820:51820/udp"
            "46931:46931/tcp"
            "46931:46931/udp"
          ];
          extraOptions = [
            "--cap-add=NET_ADMIN"
            "--device=/dev/net/tun:/dev/net/tun:rwm"
          ];
        };
        "animarr" = {
          image = "lscr.io/linuxserver/sonarr:latest";
          environment = {
            "PGID" = "0";
            "PUID" = "0";
            "TZ" = timeZone;
          };
          volumes = [
            "${dataDir}/configs/animarr:/config:rw"
            "${mediaServerDir}:/data:rw"
          ];
          dependsOn = [
            "qbittorrent"
            "tailscale"
          ];
          network."tailnet" = {};
        };
        "animlarr" = {
          image = "lscr.io/linuxserver/prowlarr:latest";
          environment = {
            "PGID" = "0";
            "PUID" = "0";
            "TZ" = timeZone;
          };
          volumes = [
            "${dataDir}/configs/animlarr:/config:rw"
          ];
          dependsOn = [
            "qbittorrent"
            "tailscale"
          ];
          network."tailnet" = {};
        };
        "caddy" = {
          image = "caddy:2-alpine";
          environmentFiles = [
            config.age.secrets.madoka-mediaserver-caddy.path
          ];
          volumes = [
            "${caddyDir}:/etc/caddy:ro"
            "${dataDir}/configs/caddy:/config:rw"
            "${dataDir}/data/caddy:/data:rw"
          ];
          dependsOn = [
            "tailscale"
          ];
          network."container:tailscale" = {};
          extraOptions = [
            "--cap-add=NET_ADMIN"
          ];
        };
        "flaresolverr" = {
          image = "ghcr.io/flaresolverr/flaresolverr:latest";
          environment = {
            "CAPTCHA_SOLVER" = "none";
            "LOG_HTML" = "false";
            "LOG_LEVEL" = "info";
            "TZ" = timeZone;
          };
          dependsOn = [
            "tailscale"
          ];
          network."tailnet" = {};
        };
        "jackett" = {
          image = "lscr.io/linuxserver/jackett:latest";
          environment = {
            "PGID" = "0";
            "PUID" = "0";
            "TZ" = timeZone;
          };
          volumes = [
            "${dataDir}/configs/jackett:/config:rw"
          ];
          dependsOn = [
            "qbittorrent"
            "tailscale"
          ];
          network."tailnet" = {};
        };
        "jellyfin" = {
          image = "lscr.io/linuxserver/jellyfin:latest";
          environment = {
            "NVIDIA_VISIBLE_DEVICES" = "all";
            "PGID" = "0";
            "PUID" = "0";
            "TZ" = timeZone;
          };
          volumes = [
            "${dataDir}/configs/jellyfin:/config:rw"
            "${dataDir}/jellyfin/cache:/cache:rw"
            "${mediaServerDir}:/data:rw"
          ];
          ports = [
            "8096:8096/tcp"
            "7359:7359/udp"
            "1900:1900/udp"
          ];
          dependsOn = [
            "qbittorrent"
            "tailscale"
          ];
          network."tailnet" = {};
          extraOptions = [
            "--device=/dev/dri/renderD128:/dev/dri/renderD128:rwm"
            "--group-add=107"
            "--group-add=44"
          ];
        };
        "jellyseerr" = {
          image = "fallenbagel/jellyseerr:latest";
          environment = {
            "LOG_LEVEL" = "debug";
            "TZ" = timeZone;
          };
          volumes = [
            "${dataDir}/configs/jellyseerr:/app/config:rw"
          ];
          ports = [
            "5055:5055/tcp"
          ];
          dependsOn = [
            "qbittorrent"
            "tailscale"
          ];
          network."tailnet" = {};
        };
        "prowlarr" = {
          image = "lscr.io/linuxserver/prowlarr:latest";
          environment = {
            "PGID" = "0";
            "PUID" = "0";
            "TZ" = timeZone;
          };
          volumes = [
            "${dataDir}/configs/prowlarr:/config:rw"
          ];
          dependsOn = [
            "qbittorrent"
            "tailscale"
          ];
          network."tailnet" = {};
        };
        "qbittorrent" = {
          image = "lscr.io/linuxserver/qbittorrent:latest";
          # image = "nginx";
          environment = {
            "DOCKER_MODS" = "ghcr.io/vuetorrent/vuetorrent-lsio-mod:latest";
            "PGID" = "0";
            "PUID" = "0";
            "TZ" = timeZone;
            "WEBUI_PORT" = "8081";
          };
          volumes = [
            "${dataDir}/configs/qbittorrent:/config:rw"
            "${dataDir}/qbittorrent/downloads:/downloads:rw"
            "${mediaServerDir}:/data:rw"
            "${torrentDir}:/torrent:rw"
          ];
          dependsOn = [
            "GlueTun-VPN"
          ];
          network."container:GlueTun-VPN" = {};
        };
        "radanimarr" = {
          image = "lscr.io/linuxserver/radarr:latest";
          environment = {
            "PGID" = "0";
            "PUID" = "0";
            "TZ" = timeZone;
          };
          volumes = [
            "${dataDir}/configs/radanimarr:/config:rw"
            "${mediaServerDir}:/data:rw"
          ];
          dependsOn = [
            "qbittorrent"
            "tailscale"
          ];
          network."tailnet" = {};
        };
        "radarr" = {
          image = "lscr.io/linuxserver/radarr:latest";
          environment = {
            "PGID" = "0";
            "PUID" = "0";
            "TZ" = timeZone;
          };
          volumes = [
            "${dataDir}/configs/radarr:/config:rw"
            "${mediaServerDir}:/data:rw"
          ];
          dependsOn = [
            "qbittorrent"
            "tailscale"
          ];
          network."tailnet" = {};
        };
        "sonarr" = {
          image = "lscr.io/linuxserver/sonarr:latest";
          environment = {
            "PGID" = "0";
            "PUID" = "0";
            "TZ" = timeZone;
          };
          volumes = [
            "${dataDir}/configs/sonarr:/config:rw"
            "${mediaServerDir}:/data:rw"
          ];
          dependsOn = [
            "qbittorrent"
            "tailscale"
          ];
          network."tailnet" = {};
        };
        "lidarr" = {
          image = "lscr.io/linuxserver/lidarr:latest";
          environment = {
            "PGID" = "0";
            "PUID" = "0";
            "TZ" = timeZone;
          };
          volumes = [
            "${dataDir}/configs/lidarr:/config:rw"
            "${dataDir}/data/lidarr:/lidarr:rw"
            "${mediaServerDir}:/data:rw"
          ];
          dependsOn = [
            "qbittorrent"
            "tailscale"
          ];
          network."tailnet" = {};
        };
      };
    };
  }
]
