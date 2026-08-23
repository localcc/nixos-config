{
  config,
  inputs,
  ...
}:
let
    dataDir = "/mnt/Storage/Docker/compose/booklore";
    storageDir = "${dataDir}/books";
    bookdropDir = "${dataDir}/drop";
    databaseDir = "${dataDir}/mariadb";
    databaseUrl = "jdbc:mariadb://booklore_db:3306/booklore";
    timeZone = "Europe/Prague";
in
{
    age.secrets.madoka-booklore.file = (inputs.secrets + /madoka-booklore.age);
    users.groups.booklore = {
        name = "booklore";
        gid = 2012;
    };
    users.users.booklore = {
        name = "booklore";
        gid = 2012;
    };

    compose.stacks = {
        "booklore" = {
            "booklore_server" = {
                image = "ghcr.io/booklore-app/booklore:latest";
                environment = {
                    "USER_UID" = "2012";
                    "USER_GID" = "2012";
                    "TZ" = "${timeZone}";
                    "DATABASE_URL" = "jdbc:mariadb://booklore_db:3306/booklore";
                };
                environmentFiles = [
                    config.age.secrets.madoka-booklore.path
                ];
                user = "2012:2012";
                volumes = [
                    "${dataDir}:/app/data"
                    "${storageDir}:/books"
                    "${bookdropDir}:/bookdrop"
                ];
                ports = [
                    "6060:6060"
                ];
                dependsOn = [
                    "booklore_db"
                ];
                network."booklore" = {};
            };
            "booklore_db" = {
                image = "lscr.io/linuxserver/mariadb:11.4.5";
                environment = [
                    "TZ" = "${timeZone}";
                ];
                environmentFiles = [
                    config.age.secrets.madoka-booklore.path
                ];
                volumes = [
                    "${databaseDir}/config:/config"
                ];
                network."booklore" = {};
            };
        };
    };
    compose.networks = {
        "booklore" = {};
    };
}