{ config, pkgs, ... }:

{
  boot.supportedFilesystems = [ "btrfs" ];

  environment.systemPackages = with pkgs; [
    btrfs-progs
    compsize
  ];

  # Ensure mountpoints exist before mounts
  systemd.tmpfiles.rules = [
    "d /data 0755 root root -"
    "d /data/media 0755 root root -"
    "d /data/obsidian 0755 root root -"
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

  # Create symlinks for convenience
  systemd.services.setup-storage-links = {
    description = "Setup storage symlinks";
    after = [ "local-fs.target" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      ln -sfn /data/media/movies /movies
      ln -sfn /data/media/tv /tv
      ln -sfn /data/media /media
      ln -sfn /data/obsidian /obsidian

      # Ensure proper permissions for your user (UID 1000)
      chown -R 1000:1000 /data/media /data/obsidian 2>/dev/null || true
    '';
  };

systemd.services.setup-user-links = {
  description = "Setup /data symlink in home";
  after = [ "local-fs.target" ];
  wantedBy = [ "multi-user.target" ];
  serviceConfig = {
    Type = "oneshot";
    RemainAfterExit = true;
  };
  script = ''
    # Link /data into /home/nixos/data
    ln -sfn /data /home/nixos/data
    chown -R nixos:users /home/nixos/data
  '';
};

  # Monthly Btrfs scrub
  systemd.services.btrfs-scrub = {
    description = "Btrfs scrub on /data";
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.btrfs-progs}/bin/btrfs scrub start -B /data";
    };
  };

  systemd.timers.btrfs-scrub = {
    description = "Monthly Btrfs scrub";
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "monthly";
      Persistent = true;
    };
  };
}
