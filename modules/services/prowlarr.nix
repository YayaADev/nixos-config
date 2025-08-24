{ config, lib, pkgs, ... }:

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

  systemd.tmpfiles.rules = [
    "Z /var/lib/prowlarr 0755 prowlarr prowlarr -"
  ];
}