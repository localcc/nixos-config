{
  config,
  inputs,
  lib,
  ...
}:
let
  wifi = config.wifi;
in
{
  options = {
    wifi = {
      enable = lib.mkEnableOption "WiFi";
    };
  };

  config = lib.mkMerge [
    (lib.mkIf wifi.enable {
      # wifi
      age.secrets.wifi-home.file = (inputs.secrets + /wifi-home.age);
      networking.networkmanager.ensureProfiles = {
        environmentFiles = [
          config.age.secrets.wifi-home.path
        ];

        profiles = {
          Home = {
            connection = {
              id = "$HOME_SSID";
              type = "wifi";
            };
            wifi = {
              mode = "infrastructure";
              ssid = "$HOME_SSID";
            };
            wifi-security = {
              key-mgmt = "wpa-psk";
              psk = "$HOME_PSK";
            };
          };
        };
      };
    })
    (lib.mkIf true {
      networking.networkmanager.enable = true;

      # mdns
      services.avahi.enable = lib.mkDefault false;
      services.resolved.enable = true;

      # ssh
      services.openssh = {
        enable = true;
        settings = {
          PasswordAuthentication = false;
        };
      };
    })
  ];
}
