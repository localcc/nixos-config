{
  inputs,
  hostname,
  pkgs,
  ...
}:
{
  imports = [
    ./users.nix
    ./nix.nix
    inputs.agenix.nixosModules.default
  ];

  # allow unfree
  nixpkgs.config.allowUnfree = true;
  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  environment.systemPackages = [
    # age
    pkgs.agenix
    pkgs.nil
    pkgs.nixd
  ];
}
