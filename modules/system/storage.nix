{pkgs, ...}: let
  constants = import ../../constants.nix;
in {
  boot.supportedFilesystems = ["btrfs"];

  environment.systemPackages = with pkgs; [
    btrfs-progs
    compsize
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
      # Obsidian stays as is
      "d /data/obsidian 0755 root root -"
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
          ln -sfn /data/obsidian /obsidian

          # Set media group ownership with SGID for new files to inherit group
          chown -R root:${constants.mediaGroup.name} /data/media /data/torrents 2>/dev/null || true
          chmod -R g+w /data/media /data/torrents 2>/dev/null || true
          find /data/media /data/torrents -type d -exec chmod 2775 {} \; 2>/dev/null || true

          # Keep obsidian as nixos user with restricted permissions
          chown -R nixos:users /data/obsidian 2>/dev/null || true
          chmod -R 750 /data/obsidian 2>/dev/null || true  # Remove world access
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
          chown -R nixos:users /home/nixos/data
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
