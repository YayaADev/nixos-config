{
  pkgs,
  constants,
  ...
}:
{
  boot.supportedFilesystems = [ "btrfs" ];

  environment.systemPackages = with pkgs; [
    btrfs-progs
    compsize
    acl
  ];

  services.journald.extraConfig = ''
    SystemMaxUse=500M
    MaxRetentionSec=30day
  '';

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
      depends = [ "/data" ];
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
      depends = [ "/data" ];
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
      depends = [ "/data" ];
    };
  };

  systemd = {
    tmpfiles.rules = [
      "d /data 0755 root root -"

      # Media directories with SGID bit (2775) for proper group inheritance
      "d /data/media 2775 root ${constants.mediaGroup.name} -"

      # Too much headache with permissions of qbit in podmnan, full access
      "d /data/torrents 0777 root root -"

      # Photos directory for immich
      "d /data/photos 0750 immich immich -"

      # Obsidian directory for WebDAV
      "d /data/obsidian 0775 nginx nginx -"
    ];

    services = {
      setup-storage-permissions = {
        description = "Setup proper storage permissions";
        after = [ "local-fs.target" ];
        wantedBy = [ "multi-user.target" ];
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
        };
        script = ''
          # Create symlinks
          ln -sfn /data/media/movies /home/nixos/movies
          ln -sfn /data/media/tv /home/nixos/tv
          ln -sfn /data/media /home/nixos/media
          ln -sfn /data/photos /home/nixos/photos
          ln -sfn /data/media/books /home/nixos/books
          ln -sfn /data/media/audiobooks /home/nixos/audiobooks
          ln -sfn /data/obsidian /home/nixos/obsidian
          ln -sfn /data /home/nixos/data

          chown -h nixos:users /home/nixos/data

          # Set correct ownership and permissions for media directories to media group
          chown -R root:${constants.mediaGroup.name} /data/media  2>/dev/null || true

          # Set SGID on directories (2775) - new files inherit group
          find /data/media -type d -exec chmod 2775 {} \; 2>/dev/null || true

          # Set file permissions (664) - group writable
          find /data/media -type f -exec chmod 664 {} \; 2>/dev/null || true

          # Set default ACLs for media group inheritance
          ${pkgs.acl}/bin/setfacl -R -d -m g:${constants.mediaGroup.name}:rwx /data/media 2>/dev/null || true

          # Give existing media group members access
          ${pkgs.acl}/bin/setfacl -R -m g:${constants.mediaGroup.name}:rwx /data/media 2>/dev/null || true

          # Set immich permissions (photos)
          chown -R immich:immich /data/photos 2>/dev/null || true
          chmod 750 /data/photos 2>/dev/null || true
          find /data/photos -type d -exec chmod 750 {} \; 2>/dev/null || true
          find /data/photos -type f -exec chmod 640 {} \; 2>/dev/null || true

          # Set obsidian permissions (WebDAV)
          chown -R nginx:nginx /data/obsidian 2>/dev/null || true
          chmod -R 755 /data/obsidian 2>/dev/null || true
          ${pkgs.acl}/bin/setfacl -R -m u:nixos:rwx /data/obsidian 2>/dev/null || true
          ${pkgs.acl}/bin/setfacl -R -d -m u:nixos:rwx /data/obsidian 2>/dev/null || true
          ${pkgs.acl}/bin/setfacl -R -d -m u:nginx:rwx /data/obsidian 2>/dev/null || true
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
        wantedBy = [ "timers.target" ];
        timerConfig = {
          OnCalendar = "monthly";
          Persistent = true;
        };
      };
    };
  };
}
