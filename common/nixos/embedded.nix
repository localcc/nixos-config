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
      (final: prev:
        let
          # probe-rs from git master: the GPIO bit-bang probe needs the
          # post-0.32.0 XVC/selector and flash code. probe-rs-head.patch
          # carries the two local fixes on top:
          #  - skip NVM regions without a flash loader in erase_all
          #    (STM32U585 OTP region at 0x0BFA0000 otherwise kills chip erase)
          #  - XVC no longer claims 0000:0000 selectors that are not
          #    network addresses (collided with the GPIO bit-bang probe)
          probe-rs-src = pkgs.fetchFromGitHub {
            owner = "localcc";
            repo = "probe-rs";
            rev = "0b4d86b530af7f92d55a888c881a929d1a5c0812";
            hash = "sha256-WpCKScyvDpXjR/cKOx6+bCDN4lo8hTKBqqXU1B9LMi8=";
          };
        in
        {
          libsigrok = prev.libsigrok.overrideAttrs {
            src = pkgs.fetchFromGitHub {
              owner = "sipeed";
              repo = "libsigrok";
              rev = "0ce0720421b6bcc8e65a0c94c5b2883cbfe22d7e";
              hash = "sha256-4aqX+OX4bBsvvb7b1XHKqG6u1Ek3floXDfjr27usZwo=";
            };
          };
          probe-rs-tools = prev.probe-rs-tools.overrideAttrs (old: {
            src = probe-rs-src;
            cargoDeps = pkgs.rustPlatform.fetchCargoVendor {
              name = "probe-rs-tools-0.32.0-g09811fbb";
              src = probe-rs-src;
              hash = "sha256-6zmhcO4QP3poqEriGVYNCoapnEKUFLFzryvc5D0mrKw=";
            };
            # HEAD's probe-rs-tools tests need files outside the crate
            # directory and hardware access; nixpkgs' checkFlags skip list
            # only covers the 0.32.0 release tests.
            doCheck = false;
          });
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
