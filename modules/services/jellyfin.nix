{ config, lib, pkgs, ... }:

{
  services.jellyfin = {
    enable = true;
    openFirewall = true;
    user = "jellyfin";
    group = "jellyfin";
  };

  # Ensure jellyfin user has access to media directories
  systemd.tmpfiles.rules = [
    "Z /var/lib/jellyfin 0755 jellyfin jellyfin -"
    "Z /var/cache/jellyfin 0755 jellyfin jellyfin -"
    "Z /data/media 0755 jellyfin jellyfin -"
  ];

  environment.systemPackages = with pkgs; [
    jellyfin
    jellyfin-web
    jellyfin-ffmpeg
  ];

  # Hardware acceleration setup for Rockchip RK3588
  hardware.graphics = {
    enable = true;
  };

  boot.kernelModules = [ "rockchip_rga" "rockchip_vdec" ];

  services.udev.extraRules = ''
    SUBSYSTEM=="video4linux", KERNEL=="video[0-9]*", GROUP="video", MODE="0664"
    SUBSYSTEM=="misc", KERNEL=="rga", GROUP="video", MODE="0664"
    SUBSYSTEM=="drm", KERNEL=="renderD*", GROUP="render", MODE="0664"
  '';
}