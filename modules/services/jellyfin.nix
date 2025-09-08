{
  pkgs,
  serviceHelpers,
  ...
}: let
  constants = import ../../constants.nix;
  serviceConfig = constants.services.jellyfin;
in {
  services.jellyfin = {
    enable = true;
    user = "jellyfin";
    group = "jellyfin";
  };

  systemd.tmpfiles.rules =
    serviceHelpers.createServiceDirectories "jellyfin" serviceConfig
    ++ [
      # Additional jellyfin-specific directories
      "Z /var/cache/jellyfin 0755 jellyfin jellyfin -"
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

  boot.kernelModules = ["rockchip_rga" "rockchip_vdec"];

  services.udev.extraRules = ''
    SUBSYSTEM=="video4linux", KERNEL=="video[0-9]*", GROUP="video", MODE="0664"
    SUBSYSTEM=="misc", KERNEL=="rga", GROUP="video", MODE="0664"
    SUBSYSTEM=="drm", KERNEL=="renderD*", GROUP="render", MODE="0664"
  '';
}
