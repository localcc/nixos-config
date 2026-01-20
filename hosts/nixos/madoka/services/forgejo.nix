{
  lib,
  config,
  inputs,
  pkgs,
  ...
}:
let
  dataDir = "/mnt/Storage/Docker/compose/forgejo";
  storageDir = "${dataDir}/data";
  configDir = "${dataDir}/conf";

  iniConfig = pkgs.writeTextFile {
    name = "app.ini";
    text = ''
      APP_NAME = madoka git
      APP_SLOGAN = mrow
      RUN_MODE = prod
      RUN_USER = forgejo
      WORK_PATH = /var/lib/gitea

      [database]
      DB_TYPE = sqlite3
      HOST = 127.0.0.1:3306
      NAME = forgejo
      USER = forgejo
      PASSWD =
      SCHEMA =
      SSL_MODE = disable
      PATH = /var/lib/gitea/data/forgejo.db
      LOG_SQL = fallse

      [server]
      LFS_START_SERVER = true
      LFS_JWT_SECRET_URI = file:/secret/lfs-jwt-secret
      APP_DATA_PATH = /var/lib/gitea/data
      DOMAIN = git.madoka.dev
      ROOT_URL = https://git.madoka.dev
      HTTP_PORT = 3000
      DISABLE_SSH = false
      SSH_PORT = 222

      [session]
      COOKIE_NAME = session

      [security]
      INSTALL_LOCK = true
      SECRET_KEY_URI = file:/secret/secret-key
      INTERNAL_TOKEN_URI = file:/secret/internal-token
      PASSWORD_HASH_ALGO = pbkdf2_hi

      [lfs]
      PATH = /var/lib/gitea/data/lfs

      [service]
      DISABLE_REGISTRATION = false
      ALLOW_ONLY_EXTERNAL_REGISTRATION = true
      SHOW_REGISTRATION_BUTTON = false
      ENABLE_BASIC_AUTHENTICATION = false
      ENABLE_INTERNAL_SIGNIN = false

      [openid]
      ENABLE_OPENID_SIGNUP = false
      ENABLE_OPENID_SIGNIN = false

      [oauth2]
      JWT_SECRET_URI = file:/secret/jwt-secret

      [oauth2_client]
      REGISTER_EMAIL_CONFIRM = false
      ENABLE_AUTO_REGISTRATION = true
      UPDATE_AVATAR = true
      ACCOUNT_LINKING = auto

      [actions]
      ENABLED = true
      DEFAULT_ACTIONS_URL = github

      [repository]
      ROOT = /var/lib/gitea/data/forgejo-repositories
      DEFAULT_PRIVATE = private
      DISABLE_HTTP_GIT = true

      [repository.pull-request]
      DEFAULT_MERGE_STYLE = rebase

      [repository.signing]
      DEFAULT_TRUST_MODEL = commiter

      [log]
      MODE = console
      LEVEL = info
      ROOT_PATH = /var/lib/gitea/log

      [cron.update_checker]
      ENABLED = true

      [mailer]
      ENABLED = false
    '';
  };
in
{
  users.groups.forgejo = {
    name = "forgejo";
    gid = 2001;
  };
  users.users.forgejo = {
    isNormalUser = true;
    uid = 2001;
    group = "forgejo";
  };
  
  age.secrets.madoka-forgejo-secret-key = {
    file = (inputs.secrets + /forgejo/secret-key.age);
    owner = "2001";
    mode = "600";
  };
  age.secrets.madoka-forgejo-internal-token = {
    file = (inputs.secrets + /forgejo/internal-token.age);
    owner = "2001";
    mode = "600";
  };
  age.secrets.madoka-forgejo-lfs-jwt-secret = {
    file = (inputs.secrets + /forgejo/lfs-jwt-secret.age);
    owner = "2001";
    mode = "600";
  };
  age.secrets.madoka-forgejo-jwt-secret = {
    file = (inputs.secrets + /forgejo/jwt-secret.age);
    owner = "2001";
    mode = "600";
  };
  
  compose.stacks = {
    "forgejo" = {
      "forgejo" = {
        image = "codeberg.org/forgejo/forgejo:13-rootless";
        environment = {
          "USER_UID" = "2001";
          "USER_GID" = "2001";          
        };
        user = "2001:2001";
        volumes = [
          "${storageDir}:/var/lib/gitea"
          "${configDir}:/etc/gitea"
          "${iniConfig}:/etc/gitea/app.ini"
          "${config.age.secrets.madoka-forgejo-secret-key.path}:/secret/secret-key:ro"
          "${config.age.secrets.madoka-forgejo-internal-token.path}:/secret/internal-token:ro"
          "${config.age.secrets.madoka-forgejo-lfs-jwt-secret.path}:/secret/lfs-jwt-secret:ro"
          "${config.age.secrets.madoka-forgejo-jwt-secret.path}:/secret/jwt-secret:ro"
          "/etc/localtime:/etc/localtime:ro"
        ];
        ports = [
          "222:2222"
        ];
        network."cloudflare_tunnel" = {
          ipv4-address = "172.24.0.6";
        };
        extraOptions = [
          "--userns=keep-id:uid=2001,gid=2001"
        ];
      };
    };   
  };
}
