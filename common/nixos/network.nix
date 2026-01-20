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
      age.secrets.wifi-ambra.file = (inputs.secrets + /wifi-ambra.age);
      
      networking.networkmanager.ensureProfiles = {
        environmentFiles = [
          config.age.secrets.wifi-home.path
          config.age.secrets.wifi-ambra.path
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
          Ambra1 = {
            connection = {
              id = "$AMBRA1_SSID";
              type = "wifi";
            };
            wifi = {
              mode = "infrastructure";
              ssid = "$AMBRA1_SSID";
            };
            wifi-security = {
              key-mgmt = "wpa-psk";
              psk = "$AMBRA_PSK";
            };
          };
          Ambra2 = {
            connection = {
              id = "$AMBRA2_SSID";
              type = "wifi";
            };
            wifi = {
              mode = "infrastructure";
              ssid = "$AMBRA2_SSID";
            };
            wifi-security = {
              key-mgmt = "wpa-psk";
              psk = "$AMBRA_PSK";
            };
          };
        };
      };
    })
    (lib.mkIf true {
      networking.networkmanager.enable = true;

      # mdns
      services.avahi.enable = lib.mkForce false;
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
