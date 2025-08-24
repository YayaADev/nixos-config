{ config, lib, pkgs, ... }:

{
  services.radarr = {
    enable = true;
    openFirewall = false;
    user = "radarr";
    group = "radarr";
  };

  systemd.tmpfiles.rules = [
    "Z /var/lib/radarr 0755 radarr radarr -"
    "Z /data/media 0775 radarr radarr -"
  ];
}