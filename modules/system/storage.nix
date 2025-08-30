{pkgs, ...}: let
  constants = import ../../constants.nix;
in {
  boot.supportedFilesystems = ["btrfs"];

  environment.systemPackages = with pkgs; [
    btrfs-progs
    compsize
    acl # Required for setfacl
  ];

  fileSystems = {
    "/data" = {
      device = "/dev/disk/by-label/data";
      fsType = "btrfs";
      options = [
        "compress=zstd:3"
        "space_cache=v2"
        "autodefrag"
        "noatime"
        "subvol=/"
      ];
    };

    "/data/media" = {
      device = "/dev/disk/by-label/data";
      fsType = "btrfs";
      options = [
        "compress=zstd:3"
        "space_cache=v2"
        "autodefrag"
        "noatime"
        "subvol=media"
      ];
      depends = ["/data"];
    };

    "/data/photos" = {
      device = "/dev/disk/by-label/data";
      fsType = "btrfs";
      options = [
        "compress=zstd:3"
        "space_cache=v2"
        "autodefrag"
        "noatime"
        "subvol=photos"
      ];
      depends = ["/data"];
    };

    "/data/obsidian" = {
      device = "/dev/disk/by-label/data";
      fsType = "btrfs";
      options = [
        "compress=zstd:3"
        "space_cache=v2"
        "autodefrag"
        "noatime"
        "subvol=obsidian"
      ];
      depends = ["/data"];
    };
  };

  systemd = {
    tmpfiles.rules = [
      "d /data 0755 root root -"
      # Media directories with media group ownership and group write permissions
      "d /data/media 0775 root ${constants.mediaGroup.name} -"
      "d /data/media/movies 0775 root ${constants.mediaGroup.name} -"
      "d /data/media/tv 0775 root ${constants.mediaGroup.name} -"
      "d /data/torrents 0775 root ${constants.mediaGroup.name} -"
      "d /data/torrents/incomplete 0775 root ${constants.mediaGroup.name} -"
      "d /data/torrents/complete 0775 root ${constants.mediaGroup.name} -"
      # Photos directory - GROUP READABLE so immich group members can access
      "d /data/photos 0750 immich immich -"
      "d /data/photos/upload 0750 immich immich -"
      "d /data/photos/library 0750 immich immich -"
      "d /data/photos/thumbs 0750 immich immich -"
      "d /data/photos/encoded-video 0750 immich immich -"
      # Obsidian with nginx write access for WebDAV
      "d /data/obsidian 0775 nginx nginx -"
    ];

    services = {
      setup-storage-links = {
        description = "Setup storage symlinks";
        after = ["local-fs.target"];
        wantedBy = ["multi-user.target"];
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
        };
        script = ''
          ln -sfn /data/media/movies /movies
          ln -sfn /data/media/tv /tv
          ln -sfn /data/media /media
          ln -sfn /data/photos /photos
          ln -sfn /data/obsidian /obsidian

          # Set media group ownership with SGID for new files to inherit group
          chown -R root:${constants.mediaGroup.name} /data/media /data/torrents 2>/dev/null || true
          chmod -R g+w /data/media /data/torrents 2>/dev/null || true
          find /data/media /data/torrents -type d -exec chmod 2775 {} \; 2>/dev/null || true

          # Set immich ownership for photos directory with GROUP READ access (750)
          chown -R immich:immich /data/photos 2>/dev/null || true
          chmod 750 /data/photos 2>/dev/null || true
          find /data/photos -type d -exec chmod 750 {} \; 2>/dev/null || true
          find /data/photos -type f -exec chmod 640 {} \; 2>/dev/null || true

          # Set obsidian permissions for WebDAV access
          chown -R nginx:nginx /data/obsidian 2>/dev/null || true
          chmod -R 755 /data/obsidian 2>/dev/null || true

          # Also give nixos user access via ACLs as backup
          ${pkgs.acl}/bin/setfacl -R -m u:nixos:rwx /data/obsidian 2>/dev/null || true
          ${pkgs.acl}/bin/setfacl -R -d -m u:nixos:rwx /data/obsidian 2>/dev/null || true
          ${pkgs.acl}/bin/setfacl -R -d -m u:nginx:rwx /data/obsidian 2>/dev/null || true
        '';
      };

      setup-user-links = {
        description = "Setup /data symlink in home";
        after = ["local-fs.target"];
        wantedBy = ["multi-user.target"];
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
        };
        script = ''
          ln -sfn /data /home/nixos/data
          chown -h nixos:users /home/nixos/data
        '';
      };

      btrfs-scrub = {
        description = "Btrfs scrub on /data";
        serviceConfig = {
          Type = "oneshot";
          ExecStart = "${pkgs.btrfs-progs}/bin/btrfs scrub start -B /data";
        };
      };
    };

    timers = {
      btrfs-scrub = {
        description = "Monthly Btrfs scrub";
        wantedBy = ["timers.target"];
        timerConfig = {
          OnCalendar = "monthly";
          Persistent = true;
        };
      };
    };
  };
}
