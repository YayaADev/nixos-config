{ config, lib, pkgs, serviceHelpers, ... }:
let
  constants = import ../../constants.nix;
  serviceConfig = constants.services.bazarr;
in
{
  services.bazarr = {
    enable = true;
    openFirewall = false;
    user = "bazarr";
    group = "bazarr";
  };

  systemd.tmpfiles.rules = serviceHelpers.createServiceDirectories "bazarr" serviceConfig ++ [
    "Z /data/media 0755 bazarr bazarr -"
  ];
}