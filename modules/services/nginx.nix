# Wiki https://nixos.wiki/wiki/Nginx
{
  serviceHelpers,
  pkgs,
  lib,
  ...
}: let
  constants = import ../../constants.nix;
in {
  services.nginx = {
    enable = true;

    # WebDAV module support
    additionalModules = [pkgs.nginxModules.dav];

    # Add WebDAV-specific configuration to the main nginx config
    appendHttpConfig = ''
      # WebDAV specific settings
      client_body_temp_path /tmp/nginx_webdav_temp;
      dav_access user:rw group:rw all:r;

      # WebSocket and SignalR optimizations
      map $http_upgrade $connection_upgrade {
        default upgrade;
        ""      close; # <-- This line is fixed
      }

      # Buffer settings for WebSocket connections
      proxy_buffering off;
      proxy_request_buffering off;
    '';
  };

  systemd.services.nginx.serviceConfig = {
    ProtectSystem = lib.mkForce "full";
    ReadWritePaths = [
      "/data/obsidian"
      # "/tmp/nginx_webdav_temp"
    ];
  };

  # Create WebDAV temp directory and set permissions
  systemd.tmpfiles.rules = [
    "d /tmp/nginx_webdav_temp 0755 nginx nginx -"
  ];

  # Make sure nginx can read/write to obsidian directory
  users.users.nginx.extraGroups = ["users"];
}
