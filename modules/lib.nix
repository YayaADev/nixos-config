{ config, lib, pkgs, ... }:

let
  # Helper function to create systemd tmpfiles rules for a service
  createServiceDirectories = serviceName: serviceConfig: 
    lib.optionals (serviceConfig.systemUser or false) [
      "Z /var/lib/${serviceName} 0755 ${serviceName} ${serviceName} -"
    ] ++ lib.optionals (serviceConfig.mediaAccess or false) [
      "Z /data/media 0775 ${serviceName} ${serviceName} -"
    ];

  # Helper function to create nginx virtual host for a service
  createNginxVirtualHost = staticIP: serviceName: serviceConfig:
    lib.optionalAttrs (serviceConfig ? hostname) {
      ${serviceConfig.hostname} = {
        serverName = serviceConfig.hostname;
        locations."/" = {
          proxyPass = "http://${staticIP}:${toString serviceConfig.port}";
          proxyWebsockets = true;
          extraConfig = ''
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
          '';
        };
      };
    };

  # Helper function to create firewall rules
  createFirewallRules = services: {
    allowedTCPPorts = lib.attrValues (lib.mapAttrs (name: service: service.port) services);
  };

  # Batch functions for multiple services
  createAllServiceDirectories = services:
    lib.flatten (lib.mapAttrsToList createServiceDirectories services);
    
  createAllNginxVirtualHosts = staticIP: services:
    lib.foldlAttrs 
      (acc: serviceName: serviceConfig: 
        lib.recursiveUpdate acc (createNginxVirtualHost staticIP serviceName serviceConfig)
      )
      {}
      services;

  # Export functions to _module.args so they can be used by other modules
  serviceHelpers = {
    inherit createServiceDirectories createNginxVirtualHost createFirewallRules;
    inherit createAllServiceDirectories createAllNginxVirtualHosts;
  };

in
{
  # This makes the functions available to all other modules via _module.args
  _module.args.serviceHelpers = serviceHelpers;
  
}