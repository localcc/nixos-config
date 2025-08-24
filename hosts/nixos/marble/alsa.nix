{
  pkgs, ...
}:
let
  pipewire' = pkgs.pipewire.overrideAttrs ({ patches ? [], ... }: {
    patches = [ ./patches/analog-output.conf.common.patch ] ++ patches;
  });
  wireplumber' = (pkgs.wireplumber.override { pipewire = pipewire'; });
in
{
  # Sound quirk
  services.pipewire = {
    package = pipewire';
    wireplumber.package = wireplumber';
  };

  environment.systemPackages = [ pkgs.alsa-utils ];

  systemd.user.services.alsa-master-volume = {
    enable = true;
    after = [ "sound.target" ];
    wantedBy = [ "default.target" ];
    description = "Sets alsa master volume";
    script = ''
      ${pkgs.alsa-utils}/bin/amixer -c 2 cset name='Master Playback Volume' 87
    '';
  };
}
