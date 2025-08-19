{
  lib, inputs, config, pkgs, unstable, ...
}:
let
  pipewire' = pkgs.pipewire.overrideAttrs (old: {
    # name = "pulseaudio-patched";
    pname = "${old.pname}-patched-with-pcm-control";
    # Instead of overriding some post-build action, which would require a
    # pulseaudio rebuild, we override the entire `buildCommand` to produce
    # its outputs by copying the original package's files (much faster).
    buildCommand = ''
      set -euo pipefail

      ${ # Copy original files, for each split-output (`out`, `dev` etc.).
      lib.concatStringsSep "\n" (map (outputName: ''
        echo "Copying output ${outputName}"
        set -x
        cp -a ${pkgs.pipewire.${outputName}} ''$${outputName}
        set +x
      '') old.outputs)}

      # Find this file: /nix/store/vr4mv8jppbvr96ml2chlgikmy6f9crb7-pipewire-0.3.80-lib/share/alsa-card-profile/mixer/paths/analog-output.conf.common
      #   and add these three lines:
      #
      #   [Element Master]
      #   switch = mute
      #   volume = ignore
      #
      # Directly above of this part of code:
      #
      #   [Element PCM]
      #   switch = mute
      #   volume = merge
      #   override-map.1 = all
      #   override-map.2 = all-left,all-right
      set -x
      INFILE=$out/share/alsa-card-profile/mixer/paths/analog-output.conf.common
      sed 's/\[Element PCM\]/\[Element Master\]\nswitch = mute\nvolume = ignore\n\n[Element PCM]/' $INFILE > tmp.conf
      # Ensure file changed (something was replaced)
      ! cmp tmp.conf $INFILE
      chmod +w $out/share/alsa-card-profile/mixer/paths/analog-output.conf.common
      cp tmp.conf $INFILE
      set +x
    '';
  });
  wireplumber' = (pkgs.wireplumber.override { pipewire = pipewire'; });
in
{
  imports = [
    ./hardware-configuration.nix
    inputs.chaotic.nixosModules.nyx-cache
    inputs.chaotic.nixosModules.nyx-overlay
    inputs.chaotic.nixosModules.nyx-registry
  ];

  # DE
  gnome = {
    enable = true;
    extraDconfOptions = {
      # keybindings
      "org/gnome/shell/keybindings" = {
        show-screenshot-ui = [ "F6" ];
      };
    };
  };

  # Boot
  boot.secureboot.enable = true;
  boot.kernelPackages = pkgs.linuxPackages_cachyos;

  # GPU
  hardware.nvidia = {
    modesetting.enable = true;
    powerManagement.enable = false;
    powerManagement.finegrained = false;
    # use nvidia opensource driver (not nouveau!!)
    open = true;
    nvidiaSettings = true;
  };

  # Sound quirk
  # services.pipewire.package = pkgs.pipewire.overrideAttrs ({ patches ? [], ... }: {
  #   patches = [ ./patches/analog-output.conf.common.patch ] ++ patches;
  # });
  services.pipewire.package = pipewire';
  services.pipewire.wireplumber.package = wireplumber';

  # Security
  security.polkit.enable = true;

  # Do not remove
  system.stateVersion = "24.05";
}
