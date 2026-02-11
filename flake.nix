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

    pre-commit-hooks = {
      url = "github:cachix/pre-commit-hooks.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs @ {
    self,
    nixpkgs,
    friendlyelecCM3588,
    agenix,
    treefmt-nix,
    pre-commit-hooks,
    ...
  }: let
    targetSystem = "aarch64-linux";

    # Both machines need dev tooling — x86 PC and the SBC itself
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

    # treefmt configuration — alejandra for .nix files
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
      # `nix check`
      formatting = treefmtEval.${system}.config.build.check self;

      pre-commit-check = pre-commit-hooks.lib.${system}.run {
        src = ./.;
        hooks = {
          # Auto-formats .nix files in place
          alejandra.enable = true;

          # Auto-removes dead bindings in place
          deadnix = {
            enable = true;
            settings = {
              edit = true; # modify files in place
              noLambdaArg = true;
            };
          };

          # Auto-fixes Nix anti-patterns in place
          statix = {
            enable = true;
            entry = "${(pkgsFor system).statix}/bin/statix fix";
            pass_filenames = false; # statix fix operates on the whole project at once
          };
        };
      };
    });

    # `nix develop` on either machine installs git pre-commit hooks
    devShells = forDevSystems (
      system: let
        pkgs = pkgsFor system;
      in {
        default = pkgs.mkShell {
          # Run pre-commit setup, then hand off to zsh (kitty/oh-my-zsh config intact)
          shellHook = ''
            ${self.checks.${system}.pre-commit-check.shellHook}
            exec ${pkgs.zsh}/bin/zsh
          '';

          packages = with pkgs; [
            alejandra # formatter   — also run manually: `alejandra .`
            deadnix # dead code    — also run manually: `deadnix -e .`
            statix # linter        — also run manually: `statix check .`
            nixd # Nix LSP
            agenix.packages.${system}.agenix # agenix CLI for secrets
          ];
        };
      }
    );
  };
}
