{ lib, ... }:
let
  # Helper function to create systemd tmpfiles rules for a service
  createServiceDirectories =
    serviceName: serviceConfig:
    lib.optionals (serviceConfig.systemUser or false) [
      "d /var/lib/${serviceName} 0755 ${serviceName} ${serviceName} -"
      "Z /var/lib/${serviceName} 0755 ${serviceName} ${serviceName} -"
    ];

  # Helper function to create nginx virtual host for a service
  createNginxVirtualHost =
    _serviceName: serviceConfig:
    lib.optionalAttrs (serviceConfig ? hostname) {
      ${serviceConfig.hostname} = {
        serverName = serviceConfig.hostname;
        listen = [
          {
            addr = "0.0.0.0";
            port = 80;
          }
        ];
        locations."/" = {
          proxyPass = "http://127.0.0.1:${toString serviceConfig.port}";
          proxyWebsockets = true;
        };
      };
    };

  # Helper function to create firewall rules
  createFirewallRules = services: {
    allowedTCPPorts = lib.attrValues (lib.mapAttrs (_name: service: service.port) services);
  };

  # Batch functions for multiple services
  createAllServiceDirectories =
    services: lib.flatten (lib.mapAttrsToList createServiceDirectories services);

  createAllNginxVirtualHosts =
    services:
    lib.foldlAttrs (
      acc: serviceName: serviceConfig:
      lib.recursiveUpdate acc (createNginxVirtualHost serviceName serviceConfig)
    ) { } services;

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
