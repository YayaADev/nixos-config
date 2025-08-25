{
  config,
  pkgs,
  serviceHelpers,
  ...
}: let
  constants = import ../../constants.nix;
  envVars = import ../../envVars.nix;
  serviceConfig = constants.services.qbittorrent;

  qbtUser = "qbittorrent";
  qbtGroup = "qbittorrent";
in {
  virtualisation.podman.enable = true;

  # Create qbittorrent user & group for volume mapping
  users.users.${qbtUser} = {
    isSystemUser = true;
    group = qbtGroup;
    home = "/var/lib/${qbtUser}";
    createHome = true;
    uid = 1000;
  };

  users.groups.${qbtGroup} = {
    gid = 1000;
  };

  systemd = {
    tmpfiles.rules =
      serviceHelpers.createServiceDirectories "qbittorrent" serviceConfig
      ++ [
        "d /var/lib/gluetun 0755 root root -"
        "d /var/lib/${qbtUser} 0755 1000 1000 -"
        "d /var/lib/${qbtUser}/qBittorrent 0755 1000 1000 -"
        "d /var/lib/${qbtUser}/qBittorrent/config 0755 1000 1000 -"
        "d /data/torrents 0755 1000 1000 -"
        "d /data/torrents/incomplete 0755 1000 1000 -"
        "d /data/torrents/complete 0755 1000 1000 -"
        "Z /data/media 0775 1000 1000 -"
      ];

    services.qbittorrent-health-check = {
      description = "qBittorrent-nox and Gluetun health check";
      after = [
        "podman-gluetun.service"
        "podman-qbittorrent-nox.service"
      ];
      wants = [
        "podman-gluetun.service"
        "podman-qbittorrent-nox.service"
      ];
      serviceConfig = {
        Type = "oneshot";
        User = "nobody";
        Group = "nogroup";
      };
      script = ''
        echo "Checking Gluetun VPN..."
        timeout=120
        while [ $timeout -gt 0 ]; do
          if ${pkgs.curl}/bin/curl -sf --connect-timeout 5 http://localhost:8000/v1/openvpn/status >/dev/null 2>&1; then
            echo "Gluetun is healthy"
            break
          fi
          sleep 2
          timeout=$((timeout - 2))
        done
        [ $timeout -le 0 ] && echo "Gluetun timeout" && exit 1

        echo "Checking qBittorrent-nox WebUI..."
        timeout=60
        while [ $timeout -gt 0 ]; do
          if ${pkgs.curl}/bin/curl -sf --connect-timeout 5 http://localhost:${toString serviceConfig.port}/api/v2/app/version >/dev/null 2>&1; then
            echo "qBittorrent-nox is healthy"
            break
          fi
          sleep 2
          timeout=$((timeout - 2))
        done
        [ $timeout -le 0 ] && echo "qBittorrent-nox timeout" && exit 1

        echo "Both Gluetun and qBittorrent-nox are healthy"
      '';
    };

    timers.qbittorrent-health-check = {
      description = "Periodic health check for qBittorrent stack";
      wantedBy = ["timers.target"];
      timerConfig = {
        OnBootSec = "10min";
        OnUnitActiveSec = "30min";
        Unit = "qbittorrent-health-check.service";
      };
    };
  };

  virtualisation.oci-containers.containers = {
    gluetun = {
      image = "qmcgaw/gluetun:latest";
      autoStart = true;
      extraOptions = [
        "--cap-add=NET_ADMIN"
        "--device=/dev/net/tun:/dev/net/tun"
      ];
      volumes = ["/var/lib/gluetun:/gluetun"];

      environment = {
        VPN_SERVICE_PROVIDER = "protonvpn";
        VPN_TYPE = "openvpn";
        OPENVPN_USER = envVars.vpn.username;
        OPENVPN_PASSWORD = envVars.vpn.password;
        SERVER_COUNTRIES = envVars.vpn.serverCountries or "Netherlands";
        VPN_PORT_FORWARDING = "on";
        VPN_PORT_FORWARDING_PROVIDER = "protonvpn";

        VPN_PORT_FORWARDING_UP_COMMAND = ''
          /bin/sh -c '
          until wget --quiet --spider http://127.0.0.1:${toString serviceConfig.port}/api/v2/app/version; do
            echo "Waiting for qBittorrent on port {{PORTS}}"
            sleep 5
          done
          echo "qBittorrent ready, setting port {{PORTS}}"
          wget --quiet --save-cookies /tmp/qbt-cookies.txt --keep-session-cookies \
            --post-data="username=${envVars.qbittorrent.username}&password=${envVars.qbittorrent.password}" \
            http://127.0.0.1:${toString serviceConfig.port}/api/v2/auth/login
          wget --quiet --load-cookies /tmp/qbt-cookies.txt --header="Content-Type: application/x-www-form-urlencoded" \
            --post-data="json={\"listen_port\":{{PORTS}}}" \
            http://127.0.0.1:${toString serviceConfig.port}/api/v2/app/setPreferences
          rm -f /tmp/qbt-cookies.txt
          echo "Port {{PORTS}} set successfully"
          '
        '';

        VPN_PORT_FORWARDING_DOWN_COMMAND = ''
          /bin/sh -c '
          if [ -f /tmp/qbt-port-set.pid ]; then
            kill $(cat /tmp/qbt-port-set.pid) 2>/dev/null || true
            rm -f /tmp/qbt-port-set.pid
          fi
          '
        '';

        FIREWALL_OUTBOUND_SUBNETS = constants.network.subnet;
        TZ = config.time.timeZone;
        DOT_PROVIDERS = "cloudflare";
        LOG_LEVEL = "info";
      };

      ports = [
        "${toString serviceConfig.port}:${toString serviceConfig.port}/tcp"
        "8000:8000/tcp"
      ];
    };

    qbittorrent-nox = {
      image = "qbittorrentofficial/qbittorrent-nox:latest";
      autoStart = true;
      dependsOn = ["gluetun"];
      extraOptions = [
        "--network=container:gluetun"
      ];
      volumes = [
        "/var/lib/${qbtUser}:/config"
        "/data/torrents:/downloads"
        "/data/media:/media"
      ];
      environment = {
        QBT_LEGAL_NOTICE = "confirm";
        QBT_VERSION = "latest";
        QBT_WEBUI_PORT = toString serviceConfig.port;
        PUID = "1000";
        PGID = "1000";
        TZ = config.time.timeZone;
      };
    };
  };
}
