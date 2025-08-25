{
  lib,
  pkgs,
  ...
}: let
  moduleFiles = lib.filesystem.listFilesRecursive ./modules;
  modules = builtins.filter (path: lib.hasSuffix ".nix" path) moduleFiles;

  agenix = builtins.fetchTarball {
    url = "https://github.com/ryantm/agenix/archive/main.tar.gz";
    sha256 = "sha256:06w2dxnf8qxwcmqvgyxnrrx62ca5x1cw3lminpgs112md17wa3rl";
  };
in {
  imports =
    modules
    ++ [
      "${agenix}/modules/age.nix"
      ./hardware-configuration.nix
    ];

  environment.systemPackages = with pkgs; [
    (pkgs.callPackage "${agenix}/pkgs/agenix.nix" {})
  ];

  system.stateVersion = "25.05";
}
