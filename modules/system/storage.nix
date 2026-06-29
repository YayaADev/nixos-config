{
  pkgs,
  constants,
  ...
}: let
  btrfsOpts = subvol: ["compress=zstd:3" "space_cache=v2" "noatime" "subvol=${subvol}"];
in {
  boot.supportedFilesystems = ["btrfs"];

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
      options = btrfsOpts "/";
    };

    "/var/lib" = {
      device = "/dev/disk/by-label/data";
      fsType = "btrfs";
      options = btrfsOpts "var-lib";
      depends = ["/data"];
    };

    "/data/media" = {
      device = "/dev/disk/by-label/data";
      fsType = "btrfs";
      options = btrfsOpts "media";
      depends = ["/data"];
    };

    "/data/photos" = {
      device = "/dev/disk/by-label/data";
      fsType = "btrfs";
      options = btrfsOpts "photos";
      depends = ["/data"];
    };

    "/data/obsidian" = {
      device = "/dev/disk/by-label/data";
      fsType = "btrfs";
      options = btrfsOpts "obsidian";
      depends = ["/data"];
    };
  };

  systemd = {
    tmpfiles.rules = [
      "d /data 0755 root root -"
      "d /data/media 2775 root ${constants.mediaGroup.name} -"
      "d /data/media/movies 2775 root ${constants.mediaGroup.name} -"
      "d /data/media/tv 2775 root ${constants.mediaGroup.name} -"
      "d /data/media/books 2775 root ${constants.mediaGroup.name} -"
      "d /data/media/audiobooks 2775 root ${constants.mediaGroup.name} -"
      "d /data/media/downloads 2775 root ${constants.mediaGroup.name} -"
      "d /data/media/downloads/movies 2775 qbittorrent ${constants.mediaGroup.name} -"
      "d /data/media/downloads/tv 2775 qbittorrent ${constants.mediaGroup.name} -"
      "d /data/media/downloads/chaptarr-ebooks 2775 root ${constants.mediaGroup.name} -"
      "d /data/media/downloads/chaptarr-audiobooks 2775 root ${constants.mediaGroup.name} -"
      "d /data/photos 0750 immich immich -"
      "d /data/obsidian 0775 nginx nginx -"
      "d /data/tdarr_cache 0755 tdarr tdarr -"
      "d /data/kobo 0755 syncthing syncthing -"
    ];

    services = {
      setup-storage-symlinks = {
        description = "Create convenience symlinks in home directory";
        after = ["local-fs.target"];
        wantedBy = ["multi-user.target"];
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
        };
        script = ''
          ln -sfn /data/media/movies /home/nixos/movies
          ln -sfn /data/media/tv /home/nixos/tv
          ln -sfn /data/media /home/nixos/media
          ln -sfn /data/photos /home/nixos/photos
          ln -sfn /data/media/books /home/nixos/books
          ln -sfn /data/media/audiobooks /home/nixos/audiobooks
          ln -sfn /data/obsidian /home/nixos/obsidian
          ln -sfn /data /home/nixos/data
          chown -h nixos:users /home/nixos/data
        '';
      };

      setup-media-acls = {
        description = "Ensure correct ACLs on storage directories";
        after = ["local-fs.target"];
        wantedBy = ["multi-user.target"];
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
        };
        script = let
          setfacl = "${pkgs.acl}/bin/setfacl";
          mediaGroup = constants.mediaGroup.name;
        in ''
          echo "Setting up media directory permissions..."

          chown root:${mediaGroup} /data/media
          find /data/media -type d -exec chmod 2775 {} +
          find /data/media -type f ! -perm 664 -exec chmod 664 {} +

          ${setfacl} -R -d -m g:${mediaGroup}:rwx /data/media
          ${setfacl} -R -m g:${mediaGroup}:rwx /data/media

          # Per-service user ACLs for containers whose stepped-down
          # process does not have media group membership
          ${setfacl} -R -m u:qbittorrent:rwx /data/media/downloads
          ${setfacl} -R -d -m u:qbittorrent:rwx /data/media/downloads

          ${setfacl} -R -m u:tdarr:rwx /data/media/movies /data/media/tv
          ${setfacl} -R -d -m u:tdarr:rwx /data/media/movies /data/media/tv

          ${setfacl} -R -m u:unpackerr:rwx /data/media/downloads
          ${setfacl} -R -d -m u:unpackerr:rwx /data/media/downloads

          ${setfacl} -R -m u:99:rwx /data/media/books /data/media/audiobooks /data/media/downloads
          ${setfacl} -R -d -m u:99:rwx /data/media/books /data/media/audiobooks /data/media/downloads

          echo "Setting up photos directory permissions..."
          chown -R immich:immich /data/photos
          find /data/photos -type d -exec chmod 750 {} +
          find /data/photos -type f ! -perm 640 -exec chmod 640 {} +

          echo "Setting up obsidian directory permissions..."
          chown -R nginx:nginx /data/obsidian
          chmod -R 755 /data/obsidian
          ${setfacl} -R -m u:nixos:rwx /data/obsidian
          ${setfacl} -R -d -m u:nixos:rwx /data/obsidian
          ${setfacl} -R -d -m u:nginx:rwx /data/obsidian

          echo "Setting up kobo directory permissions..."
          if [ -d /data/kobo ]; then
            chown syncthing:syncthing /data/kobo 2>/dev/null || true
            chmod 755 /data/kobo
          else
            echo "/data/kobo not yet created, skipping (will be set on next run)"
          fi

          chown -R tdarr:tdarr /var/lib/tdarr 2>/dev/null || true

          echo "ACL setup complete."
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
      setup-media-acls = {
        description = "Weekly ACL maintenance on storage directories";
        wantedBy = ["timers.target"];
        timerConfig = {
          OnCalendar = "Wed 03:00";
          Persistent = true;
        };
      };

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
