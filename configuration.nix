{
  lib,
  pkgs,
  inputs,
  ...
}: let
  moduleFiles = lib.filesystem.listFilesRecursive ./modules;
  modules = builtins.filter (path: lib.hasSuffix ".nix" path) moduleFiles;
in {
  imports = modules;

  time.timeZone = "America/Los_Angeles";
  system.stateVersion = "26.05";
  services.resolved.enable = false;

  nixpkgs.config.allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) ["netdata"];

  programs.git.enable = true;

  environment.systemPackages = with pkgs; [
    alejandra # matches flake formatter output — available system-wide on the SBC
    vim
    wget
    curl
    htop
    lsof
    tree
    unzip
    zip
    rsync
    nmap
    nettools
    tcpdump
    iotop
    nethogs
    ncdu
    which
    file
    strace
    tmux
    smartmontools
    pciutils
  ];

  nix = {
    settings = {
      experimental-features = [
        "nix-command"
        "flakes"
      ];
      download-buffer-size = 536870912;
      warn-dirty = false;
    };

    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 10d";
    };

    distributedBuilds = true;

    # Offload builds to x86 PC — kernel compilation is slow on the SBC
    buildMachines = [
      {
        hostName = "builder";
        systems = [
          "x86_64-linux"
          "aarch64-linux"
        ];
        sshUser = "nixbuilder";
        sshKey = "/root/.ssh/nixbuilder";
        maxJobs = 10;
        speedFactor = 10;
        supportedFeatures = [
          "nixos-test"
          "benchmark"
          "big-parallel"
          "kvm"
        ];
      }
    ];
  };

  system.autoUpgrade = {
    enable = true;
    flake = inputs.self.outPath;
    dates = "04:00";
    allowReboot = false;
  };
}
