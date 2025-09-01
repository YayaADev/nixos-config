# modules/system/storage.nix - FIXED VERSION
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
      # The key change: 2775 ensures SGID bit is set for group inheritance
      "d /data/media 2775 root ${constants.mediaGroup.name} -"
      "d /data/media/movies 2775 root ${constants.mediaGroup.name} -"
      "d /data/media/movies-4k 2775 root ${constants.mediaGroup.name} -"
      "d /data/media/tv 2775 root ${constants.mediaGroup.name} -"
      "d /data/media/tv-4k 2775 root ${constants.mediaGroup.name} -"
      "d /data/torrents 2775 root ${constants.mediaGroup.name} -"
      "d /data/torrents/movies 2775 qbittorrent ${constants.mediaGroup.name} -"
      "d /data/torrents/movies-4k 2775 qbittorrent ${constants.mediaGroup.name} -"
      "d /data/torrents/tv 2775 qbittorrent ${constants.mediaGroup.name} -"
      "d /data/torrents/tv-4k 2775 qbittorrent ${constants.mediaGroup.name} -"

      # Photos directory for immich
      "d /data/photos 0750 immich immich -"

      # Obsidian directory (for nginx)
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

          # Media directories: root:media with SGID for new files to inherit group
          chown -R root:${constants.mediaGroup.name} /data/media /data/torrents 2>/dev/null || true
          chmod -R g+w /data/media /data/torrents 2>/dev/null || true

          # Set SGID on all directories so new files/folders inherit the media group
          find /data/media -type d -exec chmod 2775 {} \; 2>/dev/null || true
          find /data/torrents -type d -exec chmod 2775 {} \; 2>/dev/null || true

          # Ensure files are group writable
          find /data/media -type f -exec chmod 664 {} \; 2>/dev/null || true
          find /data/torrents -type f -exec chmod 664 {} \; 2>/dev/null || true

          # Set immich ownership for photos directory with GROUP READ access (750)
          chown -R immich:immich /data/photos 2>/dev/null || true
          chmod 750 /data/photos 2>/dev/null || true
          find /data/photos -type d -exec chmod 750 {} \; 2>/dev/null || true
          find /data/photos -type f -exec chmod 640 {} \; 2>/dev/null || true

          # Set obsidian permissions for WebDAV access
          chown -R nginx:nginx /data/obsidian 2>/dev/null || true
          chmod -R 755 /data/obsidian 2>/dev/null || true

          # Give nixos user access via ACLs as backup
          ${pkgs.acl}/bin/setfacl -R -m u:nixos:rwx /data/obsidian 2>/dev/null || true
          ${pkgs.acl}/bin/setfacl -R -d -m u:nixos:rwx /data/obsidian 2>/dev/null || true
          ${pkgs.acl}/bin/setfacl -R -d -m u:nginx:rwx /data/obsidian 2>/dev/null || true

          # Set default ACLs for media group on media directories
          ${pkgs.acl}/bin/setfacl -R -d -m g:${constants.mediaGroup.name}:rwx /data/media 2>/dev/null || true
          ${pkgs.acl}/bin/setfacl -R -d -m g:${constants.mediaGroup.name}:rwx /data/torrents 2>/dev/null || true
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
