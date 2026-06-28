{
  config,
  constants,
  ...
}: let
  cfg = constants.services.koshelf;
in {
  systemd.tmpfiles.rules = [
    "d /var/lib/koshelf 0755 1000 1000 -"
  ];

  virtualisation.oci-containers.containers.koshelf = {
    image = "ghcr.io/devtigro/koshelf:latest";
    autoStart = true;

    environment = {
      KOSHELF_LIBRARY_PATH = "/books";
      KOSHELF_PORT = "3000";
      KOSHELF_TIMEZONE = config.time.timeZone;
      KOSHELF_TITLE = "KoShelf";
    };

    ports = ["${toString cfg.port}:3000"];

    volumes = [
      "/var/lib/koshelf:/data"
      "/data/kobo:/books:ro"
      "/data/kobo/.adds/koreader/settings:/settings:ro"
    ];

    extraOptions = [
      "--label=io.containers.autoupdate=registry"
      "--group-add=980"
      "--unsetenv=KOSHELF_STATISTICS_DB"
    ];
  };

  networking.firewall.allowedTCPPorts = [cfg.port];
}
