# Wiki https://nixos.wiki/wiki/Nginx
{ config, lib, pkgs, ... }:
let
  constants = import ../../constants.nix;
in
{
  services.nginx = {
    enable = true;
    
 # Loop through services to create a reverse proxy
virtualHosts = lib.mapAttrs' (serviceName: serviceConfig: {
  name = serviceConfig.hostname or serviceName;
  value = {
    serverName = serviceConfig.hostname or serviceName;
    locations."/" = {
      proxyPass = "http://${constants.network.staticIP}:${toString serviceConfig.port}";
      proxyWebsockets = true;
      extraConfig = ''
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
      '';
    };
  };
}) constants.nginxServices;

  };
}