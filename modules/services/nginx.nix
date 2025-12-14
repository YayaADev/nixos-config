# Wiki https://nixos.wiki/wiki/Nginx
{
  serviceHelpers,
  pkgs,
  lib,
  constants,
  ...
}: {
  services.nginx = {
    enable = true;
    clientMaxBodySize = "50G";

    # WebDAV module support
    additionalModules = [pkgs.nginxModules.dav];

    # Add WebDAV-specific configuration to the main nginx config
    appendHttpConfig = ''
      # WebDAV specific settings
      client_body_temp_path /tmp/nginx_webdav_temp;
      dav_access user:rw group:rw all:r;
    '';

    # Automatically create virtual hosts for all services with hostnames
    virtualHosts =
      (serviceHelpers.createAllNginxVirtualHosts constants.network.staticIP constants.nginxServices)
      //
      # Add WebDAV virtual host manually since it needs special config
      {
        "webdav.home" = {
          serverName = "webdav.home";
          listen = [
            {
              addr = "0.0.0.0";
              port = 8080;
            }
          ];

          locations."/" = {
            root = "/data/obsidian";
            extraConfig = ''
              # Enable WebDAV methods
              dav_methods PUT DELETE MKCOL COPY MOVE;
              dav_ext_methods PROPFIND;

              # Create full path automatically
              create_full_put_path on;

              # Set permissions for uploaded files
              dav_access user:rw group:rw all:r;

              # Allow larger file uploads
              client_max_body_size 100M;
              client_body_timeout 120s;

              # Handle preflight requests
              if ($request_method = 'OPTIONS') {
                add_header 'Access-Control-Allow-Origin' '*';
                add_header 'Access-Control-Allow-Methods' 'GET, POST, PUT, DELETE, OPTIONS, PROPFIND, MKCOL, COPY, MOVE';
                add_header 'Access-Control-Allow-Headers' 'DNT,User-Agent,X-Requested-With,If-Modified-Since,Cache-Control,Content-Type,Range,Depth,Destination,Overwrite';
                add_header 'Access-Control-Max-Age' 1728000;
                add_header 'Content-Type' 'text/plain; charset=utf-8';
                add_header 'Content-Length' 0;
                return 204;
              }
            '';
          };
        };
      };
  };

  systemd.services.nginx.serviceConfig = {
    ProtectSystem = lib.mkForce "full";
    ReadWritePaths = [
      "/data/obsidian"
    ];
  };

  # Create WebDAV temp directory and set permissions
  systemd.tmpfiles.rules = [
    "d /tmp/nginx_webdav_temp 0755 nginx nginx -"
  ];

  # Make sure nginx can read/write to obsidian directory
  users.users.nginx.extraGroups = ["users"];
}
