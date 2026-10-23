{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable-small";
    # This needs to be pinned because we are stuck with an old matrix version
    nixpkgs_legacy.url = "github:NixOS/nixpkgs?rev=36bd116f111570ed7944ef620a1273677610c719";
    colmena = {
      url = "github:nix-community/colmena";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    freescout-nix = {
      url = "gitlab:e1mo/freescout-nix-flake/main?host=cyberchaos.dev";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-utils.follows = "flake-utils";
    };
  };

  outputs = inputs@{ self, nixpkgs, nixpkgs_legacy, colmena, sops-nix, flake-utils, freescout-nix }: let
    overlay = import ./packages;
    allOverlays = [
      overlay
      freescout-nix.overlays.default
      colmena.overlays.default
    ];
    pkgs = import nixpkgs {
      system = "x86_64-linux";
      overlays = allOverlays;
    };
    defaultModules = [
      sops-nix.nixosModules.sops
      freescout-nix.nixosModules.freescout
      ./common/default.nix
      {
        config = {
          nixpkgs.overlays = allOverlays;
          _module.args = {
            inherit inputs;
            outputs = self;
          };
        };
        disabledModules = [ "services/web-apps/freescout.nix" ];
      }
    ];
    nodes = {
      shirley = nixpkgs;
      hamilton = nixpkgs_legacy;
      goldberg = nixpkgs_legacy;
      hopper = nixpkgs;
    };
  in {
    nixosConfigurations = builtins.mapAttrs (name: nixpkgs': nixpkgs'.lib.nixosSystem {
        system = "x86_64-linux";
        modules = defaultModules ++ [
          ./hosts/${name}/configuration.nix
          {
            _module.args.nixpkgs = nixpkgs';
          }
        ];
    }) nodes;
    
    colmenaHive = colmena.lib.makeHive ({
      meta.allowApplyAll = false;
      meta = {
        nixpkgs = import nixpkgs {
          system = "x86_64-linux";
        };
        nodeNixpkgs = builtins.mapAttrs (_: nixpkgs': import nixpkgs' {
          system = "x86_64-linux";
        }) nodes;
      };
      defaults = { name, config, ... }: {
        deployment = {
          tags = [ config.cj.deployment.environment ];
          targetHost = config.networking.fqdn;
          targetUser = null;
        };
      };
    } // builtins.mapAttrs (name: host: {
      nixpkgs = { inherit (host.config.nixpkgs) system; };
      imports = host._module.args.modules;
    }) self.nixosConfigurations);

    devShells.x86_64-linux.default = pkgs.mkShell {
      # pkgs.colmena is needed to get a current colmena version
      buildInputs = with pkgs; [ sops pkgs.colmena nixfmt yq nix-diff nix-tree ];
    };

    overlays.default = overlay;
    legacyPackages.x86_64-linux = pkgs;
  };
}
