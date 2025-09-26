# modules/monitoring/grafana-prometheus.nix
{
  config,
  lib,
  pkgs,
  constants,
  ...
}: let
  grafanaConfig = constants.services.grafana;
  prometheusConfig = constants.services.prometheus;
in {
  # Prometheus - metrics collection
  services.prometheus = {
    enable = true;
    inherit (prometheusConfig) port;

    # Exporters for system metrics
    exporters = {
      node = {
        enable = true;
        enabledCollectors = [
          "network"
          "diskstats"
          "filesystem"
          "loadavg"
          "meminfo"
          "netdev"
          "stat"
        ];
      };

      # Monitor systemd services
      systemd = {
        enable = true;
      };

      # Monitor nginx if you're using it
      nginx = lib.mkIf config.services.nginx.enable {
        enable = true;
      };
    };

    # Scrape configurations
    scrapeConfigs =
      [
        {
          job_name = "node";
          static_configs = [
            {
              targets = ["localhost:${toString config.services.prometheus.exporters.node.port}"];
            }
          ];
          scrape_interval = "15s";
        }
        {
          job_name = "systemd";
          static_configs = [
            {
              targets = ["localhost:${toString config.services.prometheus.exporters.systemd.port}"];
            }
          ];
          scrape_interval = "15s";
        }
        # Add nginx monitoring if enabled
      ]
      ++ lib.optionals config.services.nginx.enable [
        {
          job_name = "nginx";
          static_configs = [
            {
              targets = ["localhost:${toString config.services.prometheus.exporters.nginx.port}"];
            }
          ];
          scrape_interval = "15s";
        }
      ];

    # Alerting rules
    rules = [
      ''
        groups:
        - name: system
          rules:
          - alert: HighCPUUsage
            expr: 100 - (avg by(instance) (rate(node_cpu_seconds_total{mode="idle"}[2m])) * 100) > 80
            for: 5m
            labels:
              severity: warning
            annotations:
              summary: High CPU usage detected

          - alert: HighMemoryUsage
            expr: (node_memory_MemTotal_bytes - node_memory_MemAvailable_bytes) / node_memory_MemTotal_bytes * 100 > 85
            for: 5m
            labels:
              severity: warning
            annotations:
              summary: High memory usage detected

          - alert: DiskSpaceLow
            expr: node_filesystem_avail_bytes{fstype!="tmpfs"} / node_filesystem_size_bytes{fstype!="tmpfs"} * 100 < 10
            for: 5m
            labels:
              severity: critical
            annotations:
              summary: Disk space running low

          - alert: ServiceDown
            expr: up == 0
            for: 2m
            labels:
              severity: critical
            annotations:
              summary: Service is down
      ''
    ];
  };

  # Grafana - visualization dashboard
  services.grafana = {
    enable = true;
    settings = {
      server = {
        http_addr = "0.0.0.0";
        http_port = grafanaConfig.port;
        domain = grafanaConfig.hostname;
        root_url = "http://${grafanaConfig.hostname}/";
      };

      security = {
        admin_user = "admin";
        admin_password = "$__file{${config.age.secrets.grafana-password.path}}";
        secret_key = "$__file{${config.age.secrets.grafana-secret.path}}";
      };

      database = {
        type = "sqlite3";
        path = "/var/lib/grafana/grafana.db";
      };
    };

    # Pre-configure Prometheus data source
    provision = {
      enable = true;
      datasources.settings.datasources = [
        {
          name = "Prometheus";
          type = "prometheus";
          url = "http://localhost:${toString prometheusConfig.port}";
          isDefault = true;
        }
      ];

      # Pre-load useful dashboards
      dashboards.settings.providers = [
        {
          name = "default";
          orgId = 1;
          folder = "";
          type = "file";
          disableDeletion = false;
          updateIntervalSeconds = 10;
          allowUiUpdates = true;
          options.path = "/var/lib/grafana/dashboards";
        }
      ];
    };
  };

  # Download community dashboards
  systemd.services.grafana-setup-dashboards = {
    description = "Setup Grafana dashboards";
    after = ["grafana.service"];
    wantedBy = ["multi-user.target"];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      User = "grafana";
    };
    script = ''
      mkdir -p /var/lib/grafana/dashboards

      # Node Exporter Full dashboard
      ${pkgs.curl}/bin/curl -so /var/lib/grafana/dashboards/node-exporter.json \
        https://grafana.com/api/dashboards/1860/revisions/37/download

      # System overview dashboard
      ${pkgs.curl}/bin/curl -so /var/lib/grafana/dashboards/system-overview.json \
        https://grafana.com/api/dashboards/11074/revisions/9/download
    '';
  };

  environment.systemPackages = with pkgs; [
    grafana
    prometheus
  ];
}
