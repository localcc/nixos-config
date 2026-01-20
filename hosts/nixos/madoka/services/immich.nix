{
  config,
  inputs,
  ...
}:
let
  dataDir = "/mnt/Storage/Docker/compose/immich";
  uploadDir = "${dataDir}/library";
  databaseDir = "${dataDir}/postgres";
  immichVersion = "v3";
  timeZone = "Europe/Prague";
in
{
  age.secrets.madoka-immich.file = (inputs.secrets + /madoka-immich.age);

  compose.stacks = {
    "immich" = {
      "immich_server" = {
        image = "ghcr.io/immich-app/immich-server:${immichVersion}";
        environment = {
          "TZ" = timeZone;
          "DB_HOSTNAME" = "immich_postgres";
          "REDIS_HOSTNAME" = "immich_redis";
        };
        environmentFiles = [
          config.age.secrets.madoka-immich.path
        ];
        volumes = [
          "${uploadDir}:/data"
          "/etc/localtime:/etc/localtime:ro"
        ];
        ports = [
          "2283:2283"
        ];
        dependsOn = [
          "immich_redis"
          "immich_postgres"
          "cloudflare_tunnel"
        ];
        network = {
          "cloudflare_tunnel" = {
            ipv4-address = "172.24.0.5";
          };
          "immich" = { };
        };
      };
      "immich_machine_learning" = {
        image = "ghcr.io/immich-app/immich-machine-learning:${immichVersion}";
        volumes = [
          "${dataDir}/model-cache:/cache"
        ];
        environmentFiles = [
          config.age.secrets.madoka-immich.path
        ];
        network."immich" = {};
      };
      "immich_redis" = {
        image = "docker.io/valkey/valkey:9@sha256:418652cfb58ef879d4978c33553735d7147016032d5aefaa14c828e611eb9dfd";
        network."immich" = {};
        healthcheck = {
          test = "redis-cli ping || exit 1";
        };
      };
      "immich_postgres" = {
        image = "ghcr.io/immich-app/postgres:14-vectorchord0.4.3-pgvectors0.2.0@sha256:bcf63357191b76a916ae5eb93464d65c07511da41e3bf7a8416db519b40b1c23";
        environment = {
          "POSTGRES_INITDB_ARGS" = "--data-checksums";
        };
        environmentFiles = [
          config.age.secrets.madoka-immich.path
        ];
        volumes = [
          "${databaseDir}:/var/lib/postgresql/data"
        ];
        network."immich" = {};
        extraOptions = [
          "--shm-size=128mb"
        ];
      };
    };
  };
  compose.networks = {
    "immich" = { };
  };
}
