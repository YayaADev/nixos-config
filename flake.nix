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
  };

  outputs =
    inputs@{
      self,
      nixpkgs,
      friendlyelecCM3588,
      agenix,
      ...
    }:
    let
      system = "aarch64-linux";
      pkgs = import nixpkgs {
        inherit system;
        config = {
          allowUnfree = true;

        };
      };

      envVars = import /home/nixos/nixos-config/envVars.nix;
      constants = import ./constants.nix {
        inherit
          inputs
          self
          envVars
          pkgs
          ;
      };
    in
    {
      nixosConfigurations.nixos-cm3588 = nixpkgs.lib.nixosSystem {
        inherit system;

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
      formatter.${system} = pkgs.nixfmt;
    };
}
