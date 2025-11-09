{
  pkgs, ...
}:
let
  pipewire' = pkgs.pipewire.overrideAttrs ({ patches ? [], ... }: {
    patches = [ ./patches/analog-output.conf.common.patch ] ++ patches;
  });
  wireplumber' = (pkgs.wireplumber.override { pipewire = pipewire'; });
  jackRetask = ./patches/hda-jack-retask.fw;
in
{
  # # Sound quirk
  # services.pipewire = {
  #   package = pipewire';
  #   wireplumber.package = wireplumber';
  # };

  environment.systemPackages = [ pkgs.alsa-utils ];

  # sound fix
  hardware.firmware = [
    (pkgs.runCommandNoCC "jack-retask" {} ''
      mkdir -p $out/lib/firmware
      # Make sure the path to the patch is correct!
      # The path './legion-alc287.patch' assumes the patch is
      # in the same directory as this .nix file.
      cp ${jackRetask} $out/lib/firmware/hda-jack-retask.fw
    '')
  ];

  boot.extraModprobeConfig = ''
    options snd-hda-intel patch=hda-jack-retask.fw,hda-jack-retask.fw,hda-jack-retask.fw,hda-jack-retask.fw
  '';

  # systemd.user.services.alsa-master-volume = {
  #   enable = true;
  #   after = [ "sound.target" ];
  #   wantedBy = [ "default.target" ];
  #   description = "Sets alsa master volume";
  #   script = ''
  #     ${pkgs.alsa-utils}/bin/amixer -c 2 cset name='Master Playback Volume' 87
  #   '';
  # };
}
