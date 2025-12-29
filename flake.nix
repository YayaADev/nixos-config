{
  description = "CM3588 home-server flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixos-rk3588 = {
      url = "github:gnull/nixos-rk3588";
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
      nixos-rk3588,
      agenix,
      ...
    }:
    let
      system = "aarch64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
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
          inherit
            inputs
            constants
            envVars
            nixos-rk3588
            ;
          rk3588 = {
            inherit nixpkgs;
            pkgsKernel = pkgs;
          };
        };
        modules = [
          # Using OPi5+ CORE module for the vendor kernel NPU support. Same Soc as this
          nixos-rk3588.nixosModules.boards.orangepi5plus.core

          # Override DTB for CM3588. idk why, claude said this tho
          (
            { lib, ... }:
            {
              hardware.deviceTree.name = lib.mkForce "rockchip/rk3588-nanopc-cm3588-nas.dtb";
            }
          )

          ./configuration.nix
          ./hardware-configuration.nix
          agenix.nixosModules.age
        ];
      };
      formatter.${system} = pkgs.nixfmt-rfc-style;
    };
}
