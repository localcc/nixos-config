{
  inputs, hostname, pkgs, ...
}:
{
  imports = [
    ./me.nix
    ./nix.nix
    inputs.agenix.nixosModules.default
  ];

  # allow unfree
  nixpkgs.config.allowUnfree = true;
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # age
  environment.systemPackages = [
    pkgs.agenix
  ];

  networking.hostName = hostname;
}
