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

    # cache server update
    (pkgs.writeShellScriptBin "nixcacheupdate" ''
      NIXPKGS_HASH=$(curl https://cache.madoka.dev/update-revs/nixpkgs-${hostname}.rev)
      nix flake lock --override-input nixpkgs github:NixOS/nixpkgs/$NIXPKGS_HASH
    '')
  ];

  networking.hostName = hostname;
}
