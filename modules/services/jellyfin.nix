{ config, lib, pkgs, ... }:

{
  services.jellyfin = {
    enable = true;
    openFirewall = true;
    user = "nixos";
    group = "users";
  };

  environment.systemPackages = with pkgs; [
    jellyfin
    jellyfin-web
    jellyfin-ffmpeg  # s Rockchip RKMPP support
  ];

  # Hardware acceleration setup for Rockchip RK3588
  # Add nixos user to video group for GPU access
  users.users.nixos.extraGroups = [ "video" "render" ];

  hardware.graphics = {
    enable = true;
  };

  boot.kernelModules = [ "rockchip_rga" "rockchip_vdec" ];

  # Device permissions for hardware acceleration
  services.udev.extraRules = ''
    # Rockchip VPU devices
    SUBSYSTEM=="video4linux", KERNEL=="video[0-9]*", GROUP="video", MODE="0664"
    SUBSYSTEM=="misc", KERNEL=="rga", GROUP="video", MODE="0664"
    # DRM devices for render
    SUBSYSTEM=="drm", KERNEL=="renderD*", GROUP="render", MODE="0664"
  '';

  # Ensure proper ownership of Jellyfin directories
  systemd.tmpfiles.rules = [
    "d /var/lib/jellyfin 0755 nixos users -"
    "d /var/cache/jellyfin 0755 nixos users -"
    "L+ /var/lib/jellyfin/media - - - - /data/media"
  ];

  # Systemd service override to ensure proper permissions
  systemd.services.jellyfin = {
      # Service starts after media is mounted
      after = [ "local-fs.target" ];
      wants = [ "local-fs.target" ];
    serviceConfig = {
      SupplementaryGroups = [ "video" "render" ];
    };
  };

  # Create a setup service to fix permissions if needed
  systemd.services.jellyfin-setup = {
    description = "Setup Jellyfin permissions and directories";
    after = [ "local-fs.target" ];
    before = [ "jellyfin.service" ];
    wantedBy = [ "jellyfin.service" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      # Ensure proper ownership of jellyfin directories
      if [ -d /var/lib/jellyfin ]; then
        chown -R nixos:users /var/lib/jellyfin
      fi
      if [ -d /var/cache/jellyfin ]; then
        chown -R nixos:users /var/cache/jellyfin
      fi
      
      echo "Jellyfin setup completed"
    '';
  };
}