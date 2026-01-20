{
  inputs,
  ...
}:
{
  # overlays
  nixpkgs.overlays = [
    inputs.agenix.overlays.default
    inputs.rust-overlay.overlays.default
    inputs.niri.overlays.niri
    inputs.proton-cachyos.overlays.default
    inputs.helium.overlays.default
    # helium 0.16.x's Qt shim aborts at startup without Qt plugins on NixOS
    (final: prev: {
      helium = prev.symlinkJoin {
        name = "helium";
        paths = [ prev.helium ];
        buildInputs = [ prev.makeWrapper ];
        postBuild = ''
          wrapProgram $out/bin/helium \
            --set QT_PLUGIN_PATH ${prev.qt6.qtbase}/lib/qt-6/plugins
        '';
      };
    })
  ];

  # auto gc
  nix.gc = {
    automatic = true;
    # not sure if this works on non darwin
    # persistent = true;
    # TODO: convert to interval for darwin
    # dates = "weekly";
    options = "--delete-older-than 30d";
  };
}
