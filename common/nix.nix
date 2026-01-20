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
    inputs.helium.overlays.default
  ];

  # auto gc
  nix.gc = {
    automatic = true;
    persistent = true;
    dates = "weekly";
    options = "--delete-older-than 30d";
  };
}
