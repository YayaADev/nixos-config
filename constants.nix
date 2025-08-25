let
  secrets = import ./envVars.nix;
  lib = import <nixpkgs/lib>;

  services = {
    # Infrastructure services
    adguard = {
      port = 3000;
      hostname = "adguard.home";
      description = "AdGuard Home DNS";
      systemUser = false; # AdGuard runs as its own service
    };
    nginx = {
      port = 80;
      description = "Nginx Web Server";
      systemUser = false; # Nginx has its own user management
    };
    cloudflared = {
      port = 7844; # Cloudflared internal port
      description = "Cloudflare Tunnel";
      systemUser = true;
      extraGroups = [ ];
    };

    # Media services
    jellyfin = {
      port = 8096;
      hostname = "jellyfin.home";
      description = "Jellyfin Media Server";
      systemUser = true;
      extraGroups = [
        "video"
        "render"
        "users"
      ];
    };
    sonarr = {
      port = 8989;
      hostname = "sonarr.home";
      description = "Sonarr TV Series Management";
      systemUser = true;
      extraGroups = [ "users" ];
      createHome = true;
      homeDir = "/var/lib/sonarr";
    };
    radarr = {
      port = 7878;
      hostname = "radarr.home";
      description = "Radarr Movie Management";
      systemUser = true;
      extraGroups = [ "users" ];
      createHome = true;
      homeDir = "/var/lib/radarr";
    };
    prowlarr = {
      port = 9696;
      hostname = "prowlarr.home";
      description = "Prowlarr Indexer Manager";
      systemUser = true;
      createHome = true;
      homeDir = "/var/lib/prowlarr";
    };
    bazarr = {
      port = 6767;
      hostname = "bazarr.home";
      description = "Bazarr Subtitle Management";
      systemUser = true;
      extraGroups = [ "users" ];
      createHome = true;
      homeDir = "/var/lib/bazarr";
    };
    flaresolverr = {
      port = 8191;
      hostname = "flaresolverr.home";
      description = "FlareSolverr CloudFlare Solver";
      systemUser = true;
    };

    qbittorrent = {
      port = 8090;
      hostname = "qbittorrent.home";
      description = "qBittorrent BitTorrent Client";
      systemUser = true;
      extraGroups = [ "users" ];
      createHome = true;
      homeDir = "/var/lib/qbittorrent";
    };

    grafana = {
      port = 3001;
      hostname = "grafana.home";
      description = "Grafana Dashboard";
      systemUser = false; # Grafana service creates its own user
    };
    prometheus = {
      port = 9090;
      hostname = "prometheus.home";
      description = "Prometheus Metrics";
      systemUser = false; # Grafana service creates its own user
    };
  };

  # Helper function to create system user configuration
  createUserForSystemService =
    serviceName: serviceConfig:
    lib.optionalAttrs (serviceConfig.systemUser or false) {
      users.${serviceName} = {
        isSystemUser = true;
        description = serviceConfig.description;
        group = serviceName;
        extraGroups = serviceConfig.extraGroups or [ ];
      }
      // lib.optionalAttrs (serviceConfig.createHome or false) {
        home = lib.mkForce (serviceConfig.homeDir or "/var/lib/${serviceName}");
        createHome = true;
      };

      groups.${serviceName} = { };
    };

in
{
  network = {
    staticIP = secrets.staticIP;
    gateway = secrets.gateway;
    interface = secrets.interface;
    subnet = secrets.subnet;
  };

  # Services configuration
  services = services;

  # Helper functions to extract data
  ports = lib.mapAttrs (name: service: service.port) services;

  # Services that have hostnames (for nginx virtual hosts)
  nginxServices = lib.filterAttrs (name: service: service ? hostname) services;

  # Services that need system users
  systemServices = lib.filterAttrs (name: service: service.systemUser or false) services;

  # All TCP ports that need to be opened in firewall
  allTcpPorts = lib.attrValues (lib.mapAttrs (name: service: service.port) services);

  # Function to create users for system services
  createUserForSystemService = createUserForSystemService;
}
