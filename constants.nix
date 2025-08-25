let
  secrets = import ./envVars.nix;
  lib = import <nixpkgs/lib>;
  
  services = {
    adguard = { 
      port = 3000; 
      hostname = "adguard.home"; 
      description = "AdGuard Home DNS"; 
    };
    nginx = { 
      port = 80; 
      description = "Nginx Web Server"; 
    };

    # Media services
    jellyfin = {
      port = 8096;
      hostname = "jellyfin.home";
      description = "Jellyfin Media Server";
    };
    sonarr = {
      port = 8989;
      hostname = "sonarr.home";
      description = "Sonarr TV Series Management";
    };
    radarr = {
      port = 7878;
      hostname = "radarr.home";
      description = "Radarr Movie Management";
    };
    prowlarr = {
      port = 9696;
      hostname = "prowlarr.home";
      description = "Prowlarr Indexer Manager";
    };
    bazarr = {
      port = 6767;
      hostname = "bazarr.home";
      description = "Bazarr Subtitle Management";
    };
    flaresolverr = {
      port = 8191;
      hostname = "flaresolverr.home";
      description = "FlareSolverr CloudFlare Solver";
    };
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
  
  # All TCP ports that need to be opened in firewall
  allTcpPorts = lib.attrValues (lib.mapAttrs (name: service: service.port) services);
}