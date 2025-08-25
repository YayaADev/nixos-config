{ config, lib, pkgs, serviceHelpers, ... }:
let
  constants = import ../../constants.nix;
  serviceConfig = constants.services.prowlarr;
in
{
  services.prowlarr = {
    enable = true;
    openFirewall = false;
  };

  systemd.services.prowlarr = {
    serviceConfig = {
      User = "prowlarr";
      Group = "prowlarr";
    };
  };

  systemd.tmpfiles.rules = serviceHelpers.createServiceDirectories "prowlarr" serviceConfig;
}