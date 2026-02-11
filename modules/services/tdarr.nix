{
  config,
  constants,
  ...
}: let
  serviceConfig = constants.services.tdarr;
  tdarrUser = "tdarr";
  tdarrGroup = "tdarr";
in {
  virtualisation.podman.enable = true;

  users.users.${tdarrUser} = {
    isSystemUser = true;
    group = tdarrGroup;
    home = "/var/lib/${tdarrUser}";
    createHome = true;
    extraGroups = [
      "video"
      "render"
      "media"
    ];
  };

  users.groups.${tdarrGroup} = {};

  systemd.tmpfiles.rules = [
    "d /var/lib/${tdarrUser} 0755 ${tdarrUser} ${tdarrGroup} -"
    "d /var/lib/${tdarrUser}/server 0755 ${tdarrUser} ${tdarrGroup} -"
    "d /var/lib/${tdarrUser}/configs 0755 ${tdarrUser} ${tdarrGroup} -"
    "d /var/lib/${tdarrUser}/logs 0755 ${tdarrUser} ${tdarrGroup} -"
    "d /data/tdarr_cache 0755 ${tdarrUser} ${tdarrGroup} -"
  ];

  virtualisation.oci-containers.containers = {
    tdarr = {
      image = "ghcr.io/haveagitgat/tdarr:latest";
      autoStart = true;

      environment = {
        # doc https://docs.tdarr.io/docs/installation/docker/run-compose
        TZ = config.time.timeZone;
        PUID = "1000";
        PGID = "980";
        serverIP = "0.0.0.0";
        serverPort = toString serviceConfig.serverPort;
        webUIPort = toString serviceConfig.port;
        internalNode = "true";
        nodeName = "InternalNode";
        inContainer = "true";
      };

      volumes = [
        "/var/lib/${tdarrUser}/server:/app/server"
        "/var/lib/${tdarrUser}/configs:/app/configs"
        "/var/lib/${tdarrUser}/logs:/app/logs"
        "/data/tdarr_cache:/temp"
        "/data/media:/media"
      ];

      ports = [
        "${toString serviceConfig.port}:${toString serviceConfig.port}"
        "${toString serviceConfig.serverPort}:${toString serviceConfig.serverPort}"
      ];

      extraOptions = [
        "--device=/dev/dri:/dev/dri"
        "--label=io.containers.autoupdate=registry"
        "--group-add=980"
      ];
    };
  };

  # Hardware access for RK3588 transcoding
  services.udev.extraRules = ''
    SUBSYSTEM=="drm", KERNEL=="renderD*", GROUP="render", MODE="0664"
    SUBSYSTEM=="drm", KERNEL=="card*", GROUP="video", MODE="0664"
  '';
}
