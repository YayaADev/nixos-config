{
  config,
  constants,
  ...
}: let
  cfg = constants.services.koinsight;
in {
  systemd.tmpfiles.rules = [
    "d /var/lib/koinsight 0755 root root -"
  ];

  virtualisation.oci-containers.containers.koinsight = {
    # Reading stats dashboard + kosync position-sync server (KOReader push API)
    image = "ghcr.io/georgesg/koinsight:latest";
    autoStart = true;

    environment = {
      TZ = config.time.timeZone;
    };

    # Internal port 3000 → host port 3002 (3000 is occupied by AdGuard)
    ports = ["${toString cfg.port}:3000"];

    volumes = [
      "/var/lib/koinsight:/app/data"
      "/data/boox-koreader-settings/statistics.sqlite3:/app/data/statistics.sqlite3:ro"
    ];

    extraOptions = [
      "--label=io.containers.autoupdate=registry"
    ];
  };
}
