{
  config,
  lib,
  serviceHelpers,
  ...
}: let
  constants = import ../../constants.nix;
  serviceConfig = constants.services.immich;
in {
  services.immich = {
    enable = true;
    port = serviceConfig.port;
    host = "0.0.0.0";
    mediaLocation = "/data/photos";

    # File-based configuration - official settings only
    settings = {
      # FFmpeg settings - using only valid options from official schema
      ffmpeg = {
        crf = 23; # Video quality (23 is high quality)
        threads = 0; # Use all available threads
        preset = "ultrafast"; # Encoding speed preset
        accel = "vaapi"; # Hardware acceleration for RK3588
        accelDecode = true; # Hardware decode
        targetVideoCodec = "h264"; # Most compatible codec
        acceptedVideoCodecs = [
          "h264"
          "hevc"
        ];
        targetAudioCodec = "aac"; # Universal audio codec
        acceptedAudioCodecs = [
          "aac"
          "mp3"
          "libopus"
        ]; # Fixed: correct codec names
        acceptedContainers = [
          "mov"
          "mp4"
          "webm"
        ];
        targetResolution = "720"; # String format, not "720p"
        maxBitrate = "0"; # No limit
        bframes = -1; # Auto
        refs = 0; # Auto
        gopSize = 0; # Auto keyframe interval
        temporalAQ = false; # Temporal adaptive quantization
        cqMode = "auto"; # Constant quality mode
        twoPass = false; # Single pass encoding
        preferredHwDevice = "auto"; # Auto hardware device selection
        transcode = "required"; # Always transcode for compatibility
        tonemap = "hable"; # HDR tone mapping
      };

      # Job concurrency settings
      job = {
        backgroundTask = {
          concurrency = 5;
        };
        smartSearch = {
          concurrency = 2;
        };
        metadataExtraction = {
          concurrency = 5;
        };
        faceDetection = {
          concurrency = 2;
        };
        search = {
          concurrency = 5;
        };
        sidecar = {
          concurrency = 5;
        };
        library = {
          concurrency = 5;
        };
        migration = {
          concurrency = 5;
        };
        thumbnailGeneration = {
          concurrency = 3;
        };
        videoConversion = {
          concurrency = 1;
        };
      };

      # Basic settings that are definitely supported
      storageTemplate = {
        enabled = true;
        template = "{{y}}/{{MM}}/{{filename}}"; # Simpler template
      };

      # Machine Learning - basic settings only
      machineLearning = {
        enabled = true;
        facialRecognition = {
          enabled = true;
        };
        clip = {
          enabled = true;
        };
      };

      # Basic server settings
      server = {
        externalDomain = "http://${serviceConfig.hostname}";
      };

      # Trash settings
      trash = {
        enabled = true;
        days = 30;
      };

      # User settings
      user = {
        deleteDelay = 7;
      };

      # Logging
      logging = {
        enabled = true;
        level = "log";
      };

      # New version check
      newVersionCheck = {
        enabled = true;
      };

      # Basic authentication
      passwordLogin = {
        enabled = true;
      };

      # Map settings - omit empty styles to avoid validation error
      map = {
        enabled = true;
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
