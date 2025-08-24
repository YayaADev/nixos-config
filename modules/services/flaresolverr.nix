{ config, lib, pkgs, ... }:
let
  constants = import ../../constants.nix;
in
{
  # OPTION 1: Use native NixOS service (try this first)
  services.flaresolverr = {
    enable = true;
    openFirewall = false;
    port = constants.services.flaresolverr.port;
  };

  # Override to use our dedicated user
  systemd.services.flaresolverr = {
    serviceConfig = {
      User = "flaresolverr";
      Group = "flaresolverr";
      RuntimeDirectory = "flaresolverr";
      StateDirectory = "flaresolverr";
    };
  };

  systemd.tmpfiles.rules = [
    "d /var/lib/flaresolverr 0755 flaresolverr flaresolverr -"
  ];

  # OPTION 2: If native service fails, uncomment this NUR version:
  # 
  # services.flaresolverr = {
  #   enable = true;
  #   openFirewall = false;
  #   port = constants.services.flaresolverr.port;
  #   package = pkgs.nur.repos.xddxdd.flaresolverr-21hsmw;
  # };
}