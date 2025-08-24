let
  secrets = import ./envVars.nix;
  lib = import <nixpkgs/lib>;
  
  # Define services 
  services = {
    # Core system services
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

    # Obsidian Notes Sync
    webdav = {
      port = 5005;
      hostname = "webdav.home";
      description = "WebDAV File Sync";
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