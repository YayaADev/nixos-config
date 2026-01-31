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
        "noatime"
        "subvol=obsidian"
      ];
      depends = [ "/data" ];
    };
  };

  systemd = {
    tmpfiles.rules = [
      "d /data 0755 root root -"
      "d /data/media 2775 root ${constants.mediaGroup.name} -"
      "d /data/torrents 0777 root root -"
      "d /data/photos 0750 immich immich -"
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
          # Symlinks (always)
          ln -sfn /data/media/movies /home/nixos/movies
          ln -sfn /data/media/tv /home/nixos/tv
          ln -sfn /data/media /home/nixos/media
          ln -sfn /data/photos /home/nixos/photos
          ln -sfn /data/media/books /home/nixos/books
          ln -sfn /data/media/audiobooks /home/nixos/audiobooks
          ln -sfn /data/obsidian /home/nixos/obsidian
          ln -sfn /data /home/nixos/data
          chown -h nixos:users /home/nixos/data

          # Heavy operations - only run once (bump version to re-run)
          MARKER="/data/.permissions_fixed_v1"
          if [ -f "$MARKER" ]; then
            echo "Permissions already set, skipping."
            exit 0
          fi

          echo "Running full permission setup..."

          # Media
          chown -R root:${constants.mediaGroup.name} /data/media
          find /data/media -type d -exec chmod 2775 {} \;
          find /data/media -type f -exec chmod 664 {} \;
          ${pkgs.acl}/bin/setfacl -R -d -m g:${constants.mediaGroup.name}:rwx /data/media
          ${pkgs.acl}/bin/setfacl -R -m g:${constants.mediaGroup.name}:rwx /data/media

          # Photos
          chown -R immich:immich /data/photos
          find /data/photos -type d -exec chmod 750 {} \;
          find /data/photos -type f -exec chmod 640 {} \;

          # Obsidian
          chown -R nginx:nginx /data/obsidian
          chmod -R 755 /data/obsidian
          ${pkgs.acl}/bin/setfacl -R -m u:nixos:rwx /data/obsidian
          ${pkgs.acl}/bin/setfacl -R -d -m u:nixos:rwx /data/obsidian
          ${pkgs.acl}/bin/setfacl -R -d -m u:nginx:rwx /data/obsidian

          touch "$MARKER"
          echo "Done."
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
