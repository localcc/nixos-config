{
  lib,
  config,
  pkgs,
  ...
}:
let
  cfg = config.embedded;
in
{
  options = {
    embedded = {
      enable = lib.mkEnableOption "Embedded development";
    };
  };

  config = lib.mkIf cfg.enable {
    nixpkgs.overlays = [
      (final: prev: {
        libsigrok = prev.libsigrok.overrideAttrs {
          src = pkgs.fetchFromGitHub {
            owner = "sipeed";
            repo = "libsigrok";
            rev = "0ce0720421b6bcc8e65a0c94c5b2883cbfe22d7e";
            hash = "sha256-4aqX+OX4bBsvvb7b1XHKqG6u1Ek3floXDfjr27usZwo=";
          };
        };
      })
    ];

    users.groups.plugdev = {
      name = "plugdev";
    };

    nixpkgs.config.segger-jlink.acceptLicense = true;
    environment.systemPackages = with pkgs; [
      nrfconnect-bluetooth-low-energy
      nrfutil
      nrf-udev
      libsigrok
      pulseview
      probe-rs-tools
    ];

    services.udev.packages = [
      pkgs.probe-rs-tools
      pkgs.picoprobe-udev-rules
      pkgs.libsigrok
    ];
    services.udev.extraRules = ''
      ATTR{idVendor}=="359f", ATTR{idProduct}=="3031", ENV{ID_SIGROK}="1"
    '';
  };
}
