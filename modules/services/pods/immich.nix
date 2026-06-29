# modules/services/immich.nix
{
  lib,
  serviceHelpers,
  constants,
  pkgs,
  config,
  ...
}: let
  serviceConfig = constants.services.immich;
in {
  #  Pin to Postgres 16. An upgrade used v17 but v16 is what works here
  services.postgresql = {
    enable = true;
    package = pkgs.postgresql_16;
    settings = {
      listen_addresses = lib.mkForce "*";
      port = 5432;
    };
  };

  virtualisation.oci-containers.containers.immich-ml-rknn = {
    image = "ghcr.io/immich-app/immich-machine-learning:release-rknn";
    autoStart = true;

    ports = [
      "127.0.0.1:3003:3003"
    ];

    environment = {
      TZ = config.time.timeZone;
      MACHINE_LEARNING_RKNN_THREADS = "2";
      MACHINE_LEARNING_REQUEST_THREADS = "1";
    };

    volumes = [
      "immich-ml-cache:/cache"
      "/sys/firmware/devicetree/base:/sys/firmware/devicetree/base:ro"
      "/proc/device-tree:/proc/device-tree:ro"
    ];

    extraOptions = [
      "--label=io.containers.autoupdate=registry"
      "--security-opt=systempaths=unconfined"
      "--security-opt=apparmor=unconfined"
      "--device=/dev/dri"
      "--device=/dev/rga"
      "--device=/dev/dma_heap"
      "--device=/dev/mpp_service"
    ];
  };

  services.immich = {
    enable = true;
    inherit (serviceConfig) port;
    host = "0.0.0.0";
    mediaLocation = "/data/photos";

    settings = {
      machineLearning = {
        enabled = true;
        urls = ["http://127.0.0.1:3003"];
        facialRecognition = {
          enabled = true;
        };
        clip = {
          enabled = true;
        };
      };

      ffmpeg = {
        crf = 23;
        threads = 0;
        preset = "ultrafast";
        accel = "rkmpp";
        accelDecode = true;
        targetVideoCodec = "h264";
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
        targetResolution = "original";
        maxBitrate = "0";
        bframes = -1;
        refs = 0;
        gopSize = 0;
        temporalAQ = false;
        cqMode = "auto";
        twoPass = false;
        preferredHwDevice = "auto";
        transcode = "optimal";
        tonemap = "hable";
      };

      job = {
        backgroundTask = {
          concurrency = 5;
        };
        smartSearch = {
          concurrency = 3;
        };
        metadataExtraction = {
          concurrency = 5;
        };
        faceDetection = {
          concurrency = 4;
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

  # Server needs device access for transcoding
  systemd.services.immich-server = {
    after = ["podman-immich-ml-rknn.service"];
    wants = ["podman-immich-ml-rknn.service"];
  };

  systemd.services.immich-server.serviceConfig = {
    PrivateDevices = lib.mkForce false;
    DeviceAllow = [
      "/dev/dri/renderD128 rw"
      "/dev/dri/renderD129 rw"
      "/dev/dri/card0 rw"
      "/dev/dri/card1 rw"
      "/dev/rga rw"
      "/dev/mpp_service rw"
      "/dev/dma_heap rw"
    ];
  };

  # Ensure ML service doesn't start (we're using container)
  systemd.services.immich-machine-learning.enable = lib.mkForce false;

  # --- Directory Structure ---
  systemd.tmpfiles.rules =
    [
      "d /data/photos 0755 immich immich -"
      "d /data/photos/upload 0755 immich immich -"
      "d /data/photos/library 0755 immich immich -"
      "d /data/photos/thumbs 0755 immich immich -"
      "d /data/photos/encoded-video 0755 immich immich -"
    ]
    ++ serviceHelpers.createServiceDirectories "immich" serviceConfig;
}
