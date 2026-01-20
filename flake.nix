{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nixpkgs-fork.url = "github:localcc/nixpkgs/unifi-datadir";
    blackwall.url = "github:localcc/blackwall";

    secrets = {
      url = "git+ssh://forgejo@ssh-git.madoka.dev:2222/localcc/nixos-config-secrets.git";
      flake = false;
    };

    agenix = {
      url = "github:ryantm/agenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    lanzaboote = {
      url = "github:nix-community/lanzaboote/v0.4.3";
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

    niri-unstable.url = "github:YaLTeR/niri";
    niri = {
      url = "github:sodiboo/niri-flake";
      inputs.niri-unstable.follows = "niri-unstable";
    };

    home-manager = {
      url = "github:nix-community/home-manager/release-25.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    ignis = {
      url = "github:/ignis-sh/ignis/main";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    ignis-gvc = {
      url = "github:/ignis-sh/ignis-gvc/main";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    matugen = {
      url = "github:/InioX/matugen/main";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    awww = {
      url = "git+https://codeberg.org/LGFae/awww";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    supergfxctl = {
      url = "github:/localcc/supergfxctl";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    NixVirt = {
      url = "https://flakehub.com/f/AshleyYakeley/NixVirt/*.tar.gz";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    noctalia = {
      url = "github:noctalia-dev/noctalia-shell";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    colmena = {
      url = "github:zhaofengli/colmena";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    disko = {
      url = "github:nix-community/disko/latest";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
  outputs =
    {
      self,
      nixpkgs,
      colmena,
      ...
    }@inputs:
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
              inputs.home-manager.nixosModules.home-manager
              {
                home-manager.extraSpecialArgs = { inherit inputs; };
                home-manager.useGlobalPkgs = true;
                home-manager.useUserPackages = true;
              }
            ];
          };
          key = "${system}Configurations";
        in
        {
          ${key} = {
            ${hostname} = config;
          };
        };

      mkColmenaHost = hostname: {
        ${hostname} = {
          imports = [
            { config._module.args = { inherit hostname; }; }
            ./hosts/nixos/${hostname}
            ./hosts/nixos/${hostname}/colmena.nix
            ./common
            ./common/nixos
          ];
        };
      };

      systems = builtins.attrNames (builtins.readDir ./hosts);
      hosts = builtins.concatMap (
        system:
        let
          hostnames = builtins.attrNames (builtins.readDir ./hosts/${system});
        in
        map (hostname: mkHost system hostname) hostnames
      ) systems;

      pkgsForSystem =
        system:
        import nixpkgs {
          inherit system;
          config.allowUnfree = true;
          overlays = [ ];
        };

      nixHosts = builtins.attrNames (builtins.readDir ./hosts/nixos);
      colmenaSystems = builtins.filter (
        hostname:
        let
          files = builtins.attrNames (builtins.readDir ./hosts/nixos/${hostname});
        in
        builtins.elem "colmena.nix" files
      ) nixHosts;
      colmenaHosts = map (hostname: mkColmenaHost hostname) colmenaSystems;
    in
    {
      colmenaHive = colmena.lib.makeHive self.outputs.colmena;

      colmena = {
        meta = {
          nixpkgs = pkgsForSystem "x86_64-linux";
          specialArgs = {
            inherit inputs;
          };
        };
      }
      // builtins.foldl' lib.recursiveUpdate { } colmenaHosts;
    }
    // builtins.foldl' lib.recursiveUpdate { } hosts;
}
