{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable-small";
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

  outputs = inputs@{ self, nixpkgs, sops-nix, flake-utils, freescout-nix }: let
    overlay = import ./packages;
    allOverlays = [
      overlay
      freescout-nix.overlays.default
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
        nixpkgs.overlays = allOverlays;
        _module.args = {
          inherit inputs;
          outputs = self;
        };
      }
    ];
  in {
    nixosConfigurations = {
      shirley = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = defaultModules ++ [
          ./hosts/shirley/configuration.nix
        ];
      };
      hamilton = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = defaultModules ++ [
          ./hosts/hamilton/configuration.nix
        ];
      };
      goldberg = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = defaultModules ++ [
          ./hosts/goldberg/configuration.nix
        ];
      };
    };

    colmena = {
      meta.allowApplyAll = false;
      meta.nixpkgs = import nixpkgs {
        system = "x86_64-linux";
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
    }) self.nixosConfigurations;

    devShells.x86_64-linux.default = pkgs.mkShell {
      buildInputs = with pkgs; [ sops colmena ];
    };

    overlays.default = overlay;
    legacyPackages.x86_64-linux = pkgs;
  };
}
