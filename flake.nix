{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs@{ self, nixpkgs, sops-nix, flake-utils }: let
    overlay = import ./packages;
    pkgs = import nixpkgs {
      system = "x86_64-linux";
      overlays = [ overlay ];
    };
    defaultModules = [
      sops-nix.nixosModules.sops
      ./common/default.nix
      {
        nixpkgs.overlays = [ overlay ];
        _module.args = {
          inherit nixpkgs;
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
    };

    colmena = {
      meta.nixpkgs = import nixpkgs {
        system = "x86_64-linux";
      };
      defaults = { name, ... }: {
        deployment = {
          # TODO: It'd probably be nice to derive that from the host-configured fqdn
          targetHost = "${name}.net.chaos.jetzt";
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
