{
  inputs,
  config,
  pkgs,
  ...
}:
let
  configFile = pkgs.writeTextFile {
    name = "oauth2-proxy.cfg";
    text = ''
      reverse_proxy = true

      http_address = "0.0.0.0:4180"
      provider = "oidc"
      provider_display_name = "meow"
      client_id = "13f7740a-3b41-4eab-a5be-2b370cf2ab11"
      oidc_issuer_url = "https://meow.madoka.dev"
      scope = "openid profile email groups"
      proxy_prefix = "/oauth2"
      cookie_domains = [ "radarr.madoka", "sonarr.madoka", "animarr.madoka", "animlarr.madoka", "radanimarr.madoka", "prowlarr.madoka" ]
      cookie_secure = false
      cookie_refresh = "1h"
      cookie_secret_file = "/cookie_secret"

      code_challenge_method = "plain"

      email_domains = [ "*" ]

      whitelist_domains = [ "*.madoka", "*.madoka.dev", "*.localcc.cc" ]
      insecure_oidc_allow_unverified_email = true

      custom_templates_dir = "/templates"
      skip_provider_button = true
    '';
  };
in
{
  age.secrets.madoka-oauth2-proxy-environment = {
    file = (inputs.secrets + /oauth2-proxy/environment.age);
    owner = "2002";
    mode = "600";
  };
  age.secrets.madoka-oauth2-proxy-cookie-secret = {
    file = (inputs.secrets + /oauth2-proxy/cookie-secret.age);
    owner = "2002";
    mode = "600";
  };

  users.groups.oauth2-proxy = {
    name = "oauth2-proxy";
    gid = 2002;
  };
  users.users.oauth2-proxy = {
    isNormalUser = true;
    uid = 2002;
    group = "oauth2-proxy";
  };

  compose.stacks = {
    "oauth2-proxy" = {
      "oauth2-proxy" = {
        image = "quay.io/oauth2-proxy/oauth2-proxy:v7.14.2";
        cmd = [
          "--config"
          "/oauth2-proxy.cfg"
        ];
        environmentFiles = [
          config.age.secrets.madoka-oauth2-proxy-environment.path
        ];
        user = "2002:2002";
        volumes = [
          "${configFile}:/oauth2-proxy.cfg:ro"
          "${./error.html}:/templates/error.html"
          "${config.age.secrets.madoka-oauth2-proxy-cookie-secret.path}:/cookie_secret:ro"
        ];
        network."tailnet" = {};
        dependsOn = [
          "tailscale"
        ];
      };
    };
  };
}
