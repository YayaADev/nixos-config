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

  nixpkgs.overlays = [
    (final: prev: {
      claude-code = prev.claude-code.overrideAttrs (old: {
        nativeBuildInputs = (old.nativeBuildInputs or []) ++ [prev.python3Packages.pyelftools];
      });
    })
  ];

  programs.git.enable = true;

  environment.systemPackages = with pkgs; [
    alejandra
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
    arp-scan
    dig
    claude-code
    nixd
    deadnix
    statix
    pre-commit
    opencode
    eza
    bat
    fastfetch
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

    # Offload builds to x86 PC — kernel compilation takes too much storage on SBC
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
