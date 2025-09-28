{
  envVars,
  pkgs,
  ...
}: let
  secrets = envVars;
  inherit (pkgs) lib;

  services = {
    adguard = {
      port = 3000;
      hostname = "adguard.home";
      description = "AdGuard Home DNS";
      systemUser = false;
    };
    nginx = {
      port = 80;
      description = "Nginx Web Server";
      systemUser = false;
    };
    cloudflared = {
      port = 7844;
      description = "Cloudflare Tunnel";
      systemUser = true;
      extraGroups = [];
    };
    webdav = {
      port = 8080;
      hostname = "webdav.home";
      description = "WebDAV Server for Obsidian";
      systemUser = false;
    };
    immich = {
      port = 3001;
      hostname = "immich.home";
      description = "Immich Photo Management";
      systemUser = false;
    };
    jellyfin = {
      port = 8096;
      hostname = "jellyfin.home";
      description = "Jellyfin Media Server";
      systemUser = true;
      extraGroups = [
        "video"
        "render"
        "users"
        "media"
      ];
    };
    jellyseerr = {
      port = 5055;
      hostname = "jellyseerr.home";
      description = "Jellyseerr Media Request Management";
      systemUser = true;
      extraGroups = [
        "users"
        "media"
      ];
      createHome = true;
      homeDir = "/var/lib/jellyseerr";
    };
    sonarr = {
      port = 8989;
      hostname = "sonarr.home";
      description = "Sonarr TV Series Management";
      systemUser = true;
      extraGroups = [
        "users"
        "media"
      ];
      createHome = true;
      homeDir = "/var/lib/sonarr";
    };
    radarr = {
      port = 7878;
      hostname = "radarr.home";
      description = "Radarr Movie Management";
      systemUser = true;
      extraGroups = [
        "users"
        "media"
      ];
      createHome = true;
      homeDir = "/var/lib/radarr";
    };
    audiobookshelf = {
      port = 13378;
      hostname = "audiobookshelf.home";
      description = lib.mkForce "Book viewing tool";
      systemUser = true;
      extraGroups = [
        "users"
        "media"
      ];
      createHome = true;
      homeDir = "/var/lib/audiobookshelf";
    };
    lazylibrarian = {
      port = 5299;
      hostname = "lazylibrarian.home";
      description = "LazyLibrarian Book Management";
      systemUser = false;
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
      extraGroups = [
        "users"
        "media"
      ];
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
      extraGroups = [
        "users"
        "media"
      ];
      createHome = true;
      homeDir = "/var/lib/qbittorrent";
    };
    grafana = {
      port = 3002;
      hostname = "grafana.home";
      description = "Grafana Dashboard";
      systemUser = false;
    };
    prometheus = {
      port = 9090;
      hostname = "prometheus.home";
      description = "Prometheus Metrics";
      systemUser = false;
    };
  };

  mediaGroup = {
    name = "media";
  };

  createUserForSystemService = serviceName: serviceConfig:
    lib.optionalAttrs (serviceConfig.systemUser or false) {
      users.${serviceName} =
        {
          isSystemUser = true;
          inherit (serviceConfig) description;
          group = serviceName;
          extraGroups = serviceConfig.extraGroups or [];
        }
        // lib.optionalAttrs (serviceConfig.createHome or false) {
          home = lib.mkForce (serviceConfig.homeDir or "/var/lib/${serviceName}");
          createHome = true;
        };

      groups.${serviceName} = {};
    };
in {
  network = {
    inherit (secrets) staticIP;
    inherit (secrets) gateway;
    inherit (secrets) interface;
    inherit (secrets) subnet;
  };

  inherit services;

  inherit mediaGroup;

  ports = lib.mapAttrs (_name: service: service.port) services;

  nginxServices = lib.filterAttrs (_name: service: service ? hostname) services;

  systemServices = lib.filterAttrs (_name: service: service.systemUser or false) services;

  allTcpPorts = lib.attrValues (lib.mapAttrs (_name: service: service.port) services);

  inherit createUserForSystemService;
}
