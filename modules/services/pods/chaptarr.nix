{
  config,
  constants,
  ...
}: let
  cfg = constants.services.chaptarr;
  hostIP = constants.network.staticIP;
in {
  systemd.tmpfiles.rules = [
    "d /var/lib/chaptarr 0755 99 100 -"
    "d /var/lib/chaptarr/config 0755 99 100 -"
  ];

  virtualisation.oci-containers.containers.chaptarr = {
    image = "docker.io/robertlordhood/chaptarr:latest";
    autoStart = true;

    environment = {
      TZ = config.time.timeZone;
    };

    ports = ["${toString cfg.port}:8789"];

    volumes = [
      "/var/lib/chaptarr/config:/config"
      "/data/media:/data/media"
    ];

    extraOptions = [
      "--label=io.containers.autoupdate=registry"
      "--add-host=prowlarr:${hostIP}"
      "--add-host=qbittorrent:${hostIP}"
    ];
  };

  networking.firewall.allowedTCPPorts = [cfg.port];
}
