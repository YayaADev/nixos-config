{
  lib,
  serviceHelpers,
  ...
}: let
  constants = import ../../constants.nix;
  serviceConfig = constants.services.immich;
in {
  services.immich = {
    enable = true;
    inherit (serviceConfig) port;
    host = "0.0.0.0";
    mediaLocation = "/data/photos";

    # Allow web interface configuration - you can set to null for web config
    settings = {
      server = {
        externalDomain = "http://${serviceConfig.hostname}";
      };
      # Optional: Configure upload limits
      image = {
        thumbnailResolution = 1440;
      };
      ffmpeg = {
        # Hardware acceleration for RK3588
        accel = "vaapi";
        accelDecode = true;
        targetVideoCodec = "h264";
        acceptedVideoCodecs = [
          "h264"
          "hevc"
          "vp9"
          "av1"
        ];
      };
    };
  };

  # Add immich user to video and render groups for hardware access
  users.users.immich.extraGroups = [
    "video"
    "render"
    "media"
  ];

  # Override systemd service to allow hardware access
  systemd.services.immich-server.serviceConfig = {
    PrivateDevices = lib.mkForce false;
    DeviceAllow = [
      "/dev/dri/renderD128 rw"
      "/dev/dri/card0 rw"
    ];
  };

  systemd.services.immich-machine-learning.serviceConfig = {
    PrivateDevices = lib.mkForce false;
    DeviceAllow = [
      "/dev/dri/renderD128 rw"
      "/dev/dri/card0 rw"
    ];
  };

  # Create necessary directories
  systemd.tmpfiles.rules =
    [
      "d /data/photos 0755 immich immich -"
      "d /data/photos/upload 0755 immich immich -"
      "d /data/photos/library 0755 immich immich -"
      "d /data/photos/thumbs 0755 immich immich -"
      "d /data/photos/encoded-video 0755 immich immich -"
    ]
    ++ serviceHelpers.createServiceDirectories "immich" serviceConfig;

  # Hardware acceleration support
  hardware.graphics = {
    enable = true;
  };

  # Kernel modules for RK3588 hardware acceleration
  boot.kernelModules = [
    "rockchip_rga"
    "rockchip_vdec"
  ];

  # Udev rules for hardware access
  services.udev.extraRules = ''
    SUBSYSTEM=="video4linux", KERNEL=="video[0-9]*", GROUP="video", MODE="0664"
    SUBSYSTEM=="misc", KERNEL=="rga", GROUP="video", MODE="0664"
    SUBSYSTEM=="drm", KERNEL=="renderD*", GROUP="render", MODE="0664"
  '';
}
