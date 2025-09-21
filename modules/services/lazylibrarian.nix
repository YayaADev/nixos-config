# modules/services/lazylibrarian.nix
{
  config,
  pkgs,
  ...
}: let
  constants = import ../../constants.nix;
  serviceConfig = constants.services.lazylibrarian;

  llUser = "lazylibrarian";
  llGroup = "lazylibrarian";
in {
  virtualisation.podman.enable = true;

  systemd.tmpfiles.rules = [
    "d /var/lib/${llUser} 0755 ${llUser} ${llGroup} -"
    "d /var/lib/${llUser}/config 0755 ${llUser} ${llGroup} -"
    "d /var/lib/${llUser}/downloads 0755 ${llUser} ${llGroup} -"
  ];

  # LazyLibrarian container configuration
  virtualisation.oci-containers.containers.lazylibrarian = {
    image = "lscr.io/linuxserver/lazylibrarian:latest";
    autoStart = true;
    dependsOn = ["gluetun"];

    environment = {
      PUID = "1000"; # using nixos user because permissions r hard
      PGID = "980";
      TZ = config.time.timeZone;
      DOCKER_MODS = "linuxserver/mods:universal-calibre";
    };

    # Volume mounts
    volumes = [
      "/var/lib/${llUser}/config:/config"
      "/data/media/books:/books"
      "/data/torrents/books:/downloads"
    ];

    extraOptions = [
      "--network=container:gluetun"
      "--label=io.containers.autoupdate=registry"
    ];
  };

  # Podman auto-update service
  systemd.services.podman-auto-update = {
    description = "Podman auto-update";
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.podman}/bin/podman auto-update";
    };
  };

  systemd.timers.podman-auto-update = {
    description = "Podman auto-update timer";
    wantedBy = ["timers.target"];
    timerConfig = {
      OnCalendar = "weekly";
      Persistent = true;
    };
  };
}
