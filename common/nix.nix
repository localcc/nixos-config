{
  inputs, config, pkgs, ...
}:
{
  # overlays
  nixpkgs.overlays = [
    inputs.agenix.overlays.default
    inputs.rust-overlay.overlays.default
  ];
}
