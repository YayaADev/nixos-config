{ lib, ... }:
let
  moduleFiles = lib.filesystem.listFilesRecursive ./modules;
  modules = builtins.filter (path: lib.hasSuffix ".nix" path) moduleFiles;
in
{
  imports = modules;

  time.timeZone = "America/Los_Angeles";
  system.stateVersion = "26.05";
  services.resolved.enable = false;
  nixpkgs.config.allowUnfreePredicate = pkg:
  builtins.elem (lib.getName pkg) [ "netdata" ];
}
