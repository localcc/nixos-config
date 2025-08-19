{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";

    agenix = {
      url = "github:ryantm/agenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    lanzaboote = {
      url = "github:nix-community/lanzaboote/v0.4.2";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    rust-overlay = {
      url = "github:oxalica/rust-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    chaotic = {
      url = "github:chaotic-cx/nyx/nyxpkgs-unstable";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
  outputs =
    inputs:
    let
      inherit (inputs.nixpkgs) lib;

      mkHost =
        system: hostname:
        let
          builder =
            if system == "darwin" then inputs.nix-darwin.lib.darwinSystem else inputs.nixpkgs.lib.nixosSystem;
          config = builder {
            specialArgs = { inherit inputs; };
            modules = [
              ./hosts/${system}/${hostname}
              ./common
              ./common/${system}
              { config._module.args = { inherit hostname; }; }
            ];
          };
          key = "${system}Configurations";
        in
        {
          ${key} = {
            ${hostname} = config;
          };
        };

      systems = builtins.attrNames (builtins.readDir ./hosts);
      hosts = builtins.concatMap (
        system:
        let
          hostnames = builtins.attrNames (builtins.readDir (./hosts/${system}));
        in
        map (hostname: mkHost system hostname) hostnames
      ) systems;
    in
    builtins.foldl' lib.recursiveUpdate { } hosts;
}
