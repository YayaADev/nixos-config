{
  lib,
  serviceHelpers,
  constants,
  ...
}:
let
  serviceConfig = constants.services.immich;
in
{
  services.immich = {
    enable = true;
    inherit (serviceConfig) port;
    host = "0.0.0.0";
    mediaLocation = "/data/photos";

    settings = {
      ffmpeg = {
        crf = 23;
        threads = 0; # Use all available threads
        preset = "ultrafast"; # Encoding speed preset
        accel = "rkmpp"; # Hardware acceleration for RK3588
        accelDecode = true; # Hardware decode
        targetVideoCodec = "h264"; # Most compatible codec
        acceptedVideoCodecs = [
          "h264"
          "hevc"
        ];
        targetAudioCodec = "aac";
        acceptedAudioCodecs = [
          "aac"
          "mp3"
          "libopus"
        ];
        acceptedContainers = [
          "mov"
          "mp4"
          "webm"
        ];
        targetResolution = "original"; # String format, not "720p"
        maxBitrate = "0"; # No limit
        bframes = -1; # Auto
        refs = 0; # Auto
        gopSize = 0; # Auto keyframe interval
        temporalAQ = false; # Temporal adaptive quantization
        cqMode = "auto"; # Constant quality mode
        twoPass = false; # Single pass encoding
        preferredHwDevice = "auto"; # Auto hardware device selection
        transcode = "optimal"; # The balance between storage and performance
        tonemap = "hable"; # HDR tone mapping
      };

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
          concurrency = 5;
        };
        videoConversion = {
          concurrency = 1;
        };
      };

      storageTemplate = {
        enabled = true;
        template = "{{y}}/{{MM}}/{{filename}}";
      };

      machineLearning = {
        enabled = true;
        facialRecognition = {
          enabled = true;
        };
        clip = {
          enabled = true;
        };
      };

      server = {
        externalDomain = "http://${serviceConfig.hostname}";
      };

      trash = {
        enabled = true;
        days = 30;
      };

      user = {
        deleteDelay = 7;
      };

      logging = {
        enabled = true;
        level = "log";
      };

      newVersionCheck = {
        enabled = true;
      };

      passwordLogin = {
        enabled = true;
      };

      map = {
        enabled = true;
      };
    };
  };

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
  systemd.tmpfiles.rules = [
    "d /data/photos 0755 immich immich -"
    "d /data/photos/upload 0755 immich immich -"
    "d /data/photos/library 0755 immich immich -"
    "d /data/photos/thumbs 0755 immich immich -"
    "d /data/photos/encoded-video 0755 immich immich -"
  ]
  ++ serviceHelpers.createServiceDirectories "immich" serviceConfig;

  # Udev rules for hardware access
  services.udev.extraRules = ''
    SUBSYSTEM=="video4linux", KERNEL=="video[0-9]*", GROUP="video", MODE="0664"
    SUBSYSTEM=="misc", KERNEL=="rga", GROUP="video", MODE="0664"
    SUBSYSTEM=="drm", KERNEL=="renderD*", GROUP="render", MODE="0664"
  '';
}
