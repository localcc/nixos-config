{
  inputs, hostname, pkgs, ...
}:
{
  imports = [
    ./users.nix
    ./nix.nix
    inputs.agenix.nixosModules.default
  ];

  # allow unfree
  nixpkgs.config.allowUnfree = true;
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # age
  environment.systemPackages = [
    pkgs.agenix
    pkgs.nil
    pkgs.nixd
  ];

  networking.hostName = hostname;
}
