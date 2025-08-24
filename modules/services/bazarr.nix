{ config, lib, pkgs, ... }:

{
  services.bazarr = {
    enable = true;
    openFirewall = false;
    user = "bazarr";
    group = "bazarr";
  };

  systemd.tmpfiles.rules = [
    "Z /var/lib/bazarr 0755 bazarr bazarr -"
    "Z /data/media 0755 bazarr bazarr -"
  ];
}