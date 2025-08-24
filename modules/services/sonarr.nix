{ config, lib, pkgs, ... }:

{
  services.sonarr = {
    enable = true;
    openFirewall = false;
    user = "sonarr";
    group = "sonarr";
  };

systemd.tmpfiles.rules = [
  "Z /var/lib/sonarr 0755 sonarr sonarr -"
  "Z /data/media 0775 sonarr sonarr -"
];
}