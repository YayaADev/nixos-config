{
  description = "CM3588 home-server flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    friendlyelecCM3588 = {
      url = "github:YayaADev/nixos-friendlyelec-cm3588";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    agenix = {
      url = "github:ryantm/agenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs @ {
    self,
    nixpkgs,
    friendlyelecCM3588,
    agenix,
    treefmt-nix,
    ...
  }: let
    targetSystem = "aarch64-linux";

    devSystems = [
      "x86_64-linux"
      "aarch64-linux"
    ];

    pkgsFor = system:
      import nixpkgs {
        inherit system;
        config.allowUnfree = true;
      };

    forDevSystems = nixpkgs.lib.genAttrs devSystems;

    treefmtEval = forDevSystems (
      system:
        treefmt-nix.lib.evalModule (pkgsFor system) {
          projectRootFile = "flake.nix";
          programs.alejandra.enable = true;
        }
    );

    envVars = import /home/nixos/nixos-config/envVars.nix;
    constants = import ./constants.nix {
      inherit envVars;
      pkgs = pkgsFor targetSystem;
    };
  in {
    nixosConfigurations.nixos-cm3588 = nixpkgs.lib.nixosSystem {
      system = targetSystem;

      specialArgs = {
        inherit inputs constants envVars;
      };

      modules = [
        friendlyelecCM3588.nixosModules.cm3588
        ./configuration.nix
        ./hardware-configuration.nix
        agenix.nixosModules.age
      ];
    };

    # `nix fmt`
    formatter = forDevSystems (system: treefmtEval.${system}.config.build.wrapper);

    checks = forDevSystems (system: {
      formatting = treefmtEval.${system}.config.build.check self;
    });

    devShells = forDevSystems (
      system: let
        pkgs = pkgsFor system;
      in {
        default = pkgs.mkShell {
          packages = with pkgs; [
            alejandra
            deadnix
            statix
            nixd
            agenix.packages.${system}.agenix
          ];
        };
      }
    );
  };
}
