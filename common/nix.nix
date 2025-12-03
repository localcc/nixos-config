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
  ];

  # auto gc
  nix.gc = {
    automatic = true;
    options = "--delete-older-than 30d";
  };
}
