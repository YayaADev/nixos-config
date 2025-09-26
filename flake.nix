{
  description = "CM3588 home-server flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
    agenix = {
      url = "github:ryantm/agenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs @ {
    self,
    nixpkgs,
    agenix,
    ...
  }: let
    system = "aarch64-linux";
    pkgs = nixpkgs.legacyPackages.${system};
    envVars = import ./envVars.nix;
    constants = import ./constants.nix {inherit inputs self envVars pkgs;};
  in {
    nixosConfigurations.nixos-cm3588 = nixpkgs.lib.nixosSystem {
      inherit system;
      specialArgs = {inherit inputs constants envVars;};
      modules = [
        ./configuration.nix
        ./hardware-configuration.nix
        agenix.nixosModules.age
      ];
    };
  };
}
