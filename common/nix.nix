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
