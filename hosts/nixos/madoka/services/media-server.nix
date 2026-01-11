{
  inputs,
  pkgs,
  lib,
  config,
  ...
}:
let
  stackName = "mediaserver";
  dataDir = "/mnt/Storage/Docker/compose/media-server";
  mediaServerDir = "/mnt/Storage/WitchHut/media-server";
  torrentDir = "/mnt/Storage/WitchHut/torrents";
  timeZone = "Europe/Amsterdam";

  mkContainer =
    {
      name,
      network ? null,
      ...
    }@args:
    let
      clean = builtins.removeAttrs args [
        "network"
        "name"
      ];
      networkName = if (network != null) then network else "media-server_default";
      isContainerNetwork = network != null && (lib.strings.hasPrefix "container:" network);
    in
    {
      virtualisation.oci-containers.containers.${name} = lib.mkMerge [
        clean
        {
          serviceName = "podman-${stackName}-${name}";
          log-driver = "journald";
        }
        (lib.mkIf (network != null) {
          extraOptions = [
            "--network=${network}"
          ];
        })
        (lib.mkIf (!isContainerNetwork) {
          extraOptions = [
            "--network-alias=${stackName}-${name}"
          ];
        })
      ];

      systemd.services."podman-${stackName}-${name}" = lib.mkMerge [
        {
          serviceConfig = {
            Restart = lib.mkOverride 90 "always";
          };
          partOf = [
            "podman-compose-media-server-root.target"
          ];
          wantedBy = [
            "podman-compose-media-server-root.target"
          ];
        }
        (lib.mkIf (!isContainerNetwork) {
          after = [
            "podman-network-${networkName}.service"
          ];
          requires = [
            "podman-network-${networkName}.service"
          ];
        })
      ];
    };

  mkNetwork =
    { name, ipam }:
    let
      networkConfig = if (ipam != null) then "--subnet=${ipam.subnet} --gateway=${ipam.gateway}" else "";
    in
    {
      systemd.services."podman-network-${name}" = {
        path = [ pkgs.podman ];
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
          ExecStop = "podman network rm -f ${name}";
        };
        script = ''
          podman network inspect ${name} || podman network create ${name} ${networkConfig}
        '';
        partOf = [ "podman-compose-media-server-root.target" ];
        wantedBy = [ "podman-compose-media-server-root.target" ];
      };
    };
in
lib.mkMerge [
  {
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
    
    age.secrets.madoka-mediaserver-caddy.file = (inputs.self + /secrets/mediaserver/caddy.age);
    age.secrets.madoka-mediaserver-gluetun.file = (inputs.self + /secrets/mediaserver/gluetun.age);
    age.secrets.madoka-mediaserver-tailscale.file = (inputs.self + /secrets/mediaserver/tailscale.age);
  }
  (mkContainer {
    name = "GlueTun-VPN";
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
  })
  (mkContainer {
    name = "animarr";
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
    network = "tailnet";
  })
  (mkContainer {
    name = "animlarr";
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
    network = "tailnet";
  })
  (mkContainer {
    name = "caddy";
    image = "caddy:2-alpine";
    environmentFiles = [
      config.age.secrets.madoka-mediaserver-caddy.path
    ];
    volumes = [
      "${dataDir}/config/caddy:/etc/caddy:rw"
      "${dataDir}/configs/caddy:/config:rw"
      "${dataDir}/data/caddy:/data:rw"
    ];
    dependsOn = [
      "tailscale"
    ];
    network = "container:tailscale";
    extraOptions = [
      "--cap-add=NET_ADMIN"
    ];
  })
  (mkContainer {
    name = "coredns";
    image = "coredns/coredns:1.13.1";
    environmentFiles = [
      config.age.secrets.madoka-mediaserver-caddy.path
    ];
    volumes = [
      "${dataDir}/config/coredns:/etc/coredns:rw"
    ];
    cmd = [
      "-conf"
      "/etc/coredns/Corefile"
    ];
    dependsOn = [
      "tailscale"
    ];
    network = "container:tailscale";
  })
  (mkContainer {
    name = "flaresolverr";
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
    network = "tailnet";
  })
  (mkContainer {
    name = "jackett";
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
    network = "tailnet";
  })
  (mkContainer {
    name = "jellyfin";
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
    network = "tailnet";
    extraOptions = [
      "--device=/dev/dri/renderD128:/dev/dri/renderD128:rwm"
      "--group-add=107"
      "--group-add=44"
    ];
  })
  (mkContainer {
    name = "jellyseerr";
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
    network = "tailnet";
  })
  (mkContainer {
    name = "prowlarr";
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
    network = "tailnet";
  })
  (mkContainer {
    name = "qbittorrent";
    image = "lscr.io/linuxserver/qbittorrent:latest";
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
    network = "container:GlueTun-VPN";
  })
  (mkContainer {
    name = "radanimarr";
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
    network = "tailnet";
  })
  (mkContainer {
    name = "radarr";
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
    network = "tailnet";
  })
  (mkContainer {
    name = "sonarr";
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
    network = "tailnet";
  })
  (mkContainer {
    name = "tailscale";
    image = "ghcr.io/tailscale/tailscale:latest";
    environment = {
      "TS_ACCEPT_DNS" = "1";
      "TS_STATE_DIR" = "/var/lib/tailscale";
    };
    environmentFiles = [
      config.age.secrets.madoka-mediaserver-tailscale.path
    ];
    volumes = [
      "${dataDir}/data/tailscale:/var/lib/tailscale:rw"
    ];
    network = "tailnet";
    extraOptions = [
      "--cap-add=NET_ADMIN"
      "--device=/dev/net/tun:/dev/net/tun:rwm"
      "--ip=172.20.0.2"
    ];
  })
  (mkNetwork {
    name = "tailnet";
    ipam = {
      subnet = "172.20.0.0/24";
      gateway = "172.20.0.1";
    };
  })
  {
    # Networks
    systemd.services."podman-network-media-server_default" = {
      path = [ pkgs.podman ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStop = "podman network rm -f media-server_default";
      };
      script = ''
        podman network inspect media-server_default || podman network create media-server_default
      '';
      partOf = [ "podman-compose-media-server-root.target" ];
      wantedBy = [ "podman-compose-media-server-root.target" ];
    };

    # Root service
    # When started, this will automatically create all resources and start
    # the containers. When stopped, this will teardown all resources.
    systemd.targets."podman-compose-media-server-root" = {
      unitConfig = {
        Description = "Root target generated by compose2nix.";
      };
      wantedBy = [ "multi-user.target" ];
      requires = [
        "tailscaled-autoconnect.service"
      ];
    };
  }
]
