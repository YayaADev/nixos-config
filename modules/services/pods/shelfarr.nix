{
  config,
  constants,
  ...
}: let
  cfg = constants.services.shelfarr;
  audiobookshelfCfg = constants.services.audiobookshelf;
  hostIP = constants.network.staticIP;
in {
  users.users.shelfarr = {
    isSystemUser = true;
    group = "shelfarr";
    home = cfg.homeDir;
    createHome = true;
    extraGroups = ["media"];
  };

  users.groups.shelfarr = {};

  systemd.tmpfiles.rules = [
    "d ${cfg.homeDir} 0755 shelfarr shelfarr -"
    "d ${cfg.homeDir}/data 0755 shelfarr shelfarr -"
  ];

  virtualisation.oci-containers.containers.shelfarr = {
    image = "ghcr.io/pedro-revez-silva/shelfarr:latest";
    autoStart = true;

    environment = {
      TZ = config.time.timeZone;
      HTTP_PORT = "8080";
      SOLID_QUEUE_IN_PUMA = "1";
      PUID = "1000";
      PGID = "1000";
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
      "/data/torrents/audiobooks:/downloads/audiobooks"
      "/data/torrents/books:/downloads/books"
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
