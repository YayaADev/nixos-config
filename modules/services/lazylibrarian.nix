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

  users.users.${llUser} = {
    isSystemUser = true;
    group = llGroup;
    home = "/var/lib/${llUser}";
    createHome = true;
    extraGroups = ["media"];
    uid = 994; # Choose an available UID
  };

  users.groups.${llGroup} = {
    gid = 994; # Choose an available GID
  };

  # Create necessary directories
  systemd.tmpfiles.rules = [
    "d /var/lib/${llUser} 0755 ${llUser} ${llGroup} -"
    "d /var/lib/${llUser}/config 0755 ${llUser} ${llGroup} -"
    "d /var/lib/${llUser}/downloads 0755 ${llUser} ${llGroup} -"
  ];

  # Health check service
  systemd.services.lazylibrarian-health-check = {
    description = "LazyLibrarian health check";
    after = ["podman-lazylibrarian.service"];
    wants = ["podman-lazylibrarian.service"];
    serviceConfig = {
      Type = "oneshot";
      User = "nobody";
      Group = "nogroup";
    };
    script = ''
      echo "Checking LazyLibrarian WebUI..."
      timeout=60
      while [ $timeout -gt 0 ]; do
        if ${pkgs.curl}/bin/curl -sf --connect-timeout 5 http://localhost:${toString serviceConfig.port}/home >/dev/null 2>&1; then
          echo "LazyLibrarian is healthy"
          exit 0
        fi
        sleep 2
        timeout=$((timeout - 2))
      done
      echo "LazyLibrarian health check timeout"
      exit 1
    '';
  };

  # Periodic health check timer
  systemd.timers.lazylibrarian-health-check = {
    description = "Periodic health check for LazyLibrarian";
    wantedBy = ["timers.target"];
    timerConfig = {
      OnBootSec = "5min";
      OnUnitActiveSec = "15min";
      Unit = "lazylibrarian-health-check.service";
    };
  };

  # LazyLibrarian container configuration
  virtualisation.oci-containers.containers.lazylibrarian = {
    image = "lscr.io/linuxserver/lazylibrarian:latest";
    autoStart = true;

    # Environment variables
    environment = {
      PUID = "994"; # Must match the UID above
      PGID = "994"; # Must match the GID above
      TZ = config.time.timeZone;
    };

    # Volume mounts
    volumes = [
      "/var/lib/${llUser}/config:/config"
      "/data/media/books:/books"
      "/data/torrents/books:/downloads"
    ];

    # Port mappings
    ports = [
      "${toString serviceConfig.port}:5299"
    ];

    # Container options
    extraOptions = [
      "--group-add=980" # Add media group GID
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
