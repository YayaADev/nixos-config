{
  config,
  constants,
  ...
}: let
  cfg = constants.services.shelfarr;
  audiobookshelfCfg = constants.services.audiobookshelf;
  hostIP = constants.network.staticIP;
in {
  systemd.tmpfiles.rules = [
    "d ${cfg.homeDir} 0755 shelfarr shelfarr -"
    "d ${cfg.homeDir}/data 0770 shelfarr shelfarr -"
  ];

  virtualisation.oci-containers.containers.shelfarr = {
    image = "ghcr.io/pedro-revez-silva/shelfarr:latest";
    autoStart = true;

    environment = {
      TZ = config.time.timeZone;
      HTTP_PORT = "8080";
      SOLID_QUEUE_IN_PUMA = "1";
      PUID = toString cfg.uid;
      PGID = toString constants.mediaGroup.gid;
      ABR_DRY_RUN = "0";
      ABR_BACKUP = "1";
      ABR_FILENAME_TEMPLATE = "{author}/{title}";
      ABS_BASE_URL = "http://${hostIP}:${toString audiobookshelfCfg.port}";
      SHELFARR_THEME = "midnight";
      SHELFARR_NAV_POSITION = "side";
    };

    ports = ["${toString cfg.port}:8080"];

    volumes = [
      "${cfg.homeDir}/data:/rails/storage"
      "/data/media/audiobooks:/audiobooks"
      "/data/media/books:/ebooks"
      "/data/media/downloads/shelfarr:/downloads"
    ];

    extraOptions = [
      "--label=io.containers.autoupdate=registry"
      "--add-host=prowlarr:${hostIP}"
      "--add-host=flaresolverr:${hostIP}"
      "--add-host=audiobookshelf:${hostIP}"
      "--add-host=qbittorrent:${hostIP}"
      "--group-add=980"
    ];
  };

  networking.firewall.allowedTCPPorts = [cfg.port];
}
