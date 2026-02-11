# modules/services/unpackerr.nix
{
  config,
  constants,
  envVars,
  ...
}: {
  virtualisation.oci-containers.containers.unpackerr = {
    image = "ghcr.io/unpackerr/unpackerr:latest";
    autoStart = true;

    environment = {
      TZ = config.time.timeZone;
      UN_INTERVAL = "2m";
      UN_START_DELAY = "1m";
      UN_RETRY_DELAY = "5m";
      UN_MAX_RETRIES = "3";
      UN_PARALLEL = "1";
      UN_FILE_MODE = "0664";
      UN_DIR_MODE = "0775";

      # Radarr
      UN_RADARR_0_URL = "http://radarr.home:${toString constants.services.radarr.port}";
      UN_RADARR_0_API_KEY = envVars.radarr.apiKey;
      UN_RADARR_0_PATHS_0 = "/data/torrents";
      UN_RADARR_0_PROTOCOLS = "torrent";
      UN_RADARR_0_DELETE_ORIG = "false";
      UN_RADARR_0_DELETE_DELAY = "5m";

      # Sonarr
      UN_SONARR_0_URL = "http://sonarr.home:${toString constants.services.sonarr.port}";
      UN_SONARR_0_API_KEY = envVars.sonarr.apiKey;
      UN_SONARR_0_PATHS_0 = "/data/torrents";
      UN_SONARR_0_PROTOCOLS = "torrent";
      UN_SONARR_0_DELETE_ORIG = "false";
      UN_SONARR_0_DELETE_DELAY = "5m";
    };

    volumes = [
      "/data/torrents:/data/torrents"
    ];

    extraOptions = [
      "--network=host" # So it can reach radarr.home, sonarr.home
      "--label=io.containers.autoupdate=registry"
    ];
  };

  users.users.unpackerr = {
    isSystemUser = true;
    group = "unpackerr";
    extraGroups = ["media"];
    uid = 1001;
  };

  users.groups.unpackerr = {
    gid = 1001;
  };
}
