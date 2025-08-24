{ lib, pkgs, ... }:

let
  moduleFiles = lib.filesystem.listFilesRecursive ./modules;
  modules = builtins.filter (path: lib.hasSuffix ".nix" path) moduleFiles;
in
{
  imports = modules ++ [
    "${(import ./nix/sources.nix).agenix}/modules/age.nix"
    ./hardware-configuration.nix
  ];


  environment.systemPackages = with pkgs; [
    (pkgs.callPackage "${(import ./nix/sources.nix).agenix}/pkgs/agenix.nix" {})
  ];

  system.stateVersion = "25.05";
}
