{
  pkgs,
  inputs,
  ...
}:
{
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
      options = "--delete-older-than 30d";
    };

    distributedBuilds = true;

    # offload some builds to my x86 PC cause kernel building is long and takes time
    buildMachines = [
      {
        hostName = "builder";
        systems = [
          "x86_64-linux"
          "aarch64-linux"
        ];
        sshUser = "nixbuilder";
        sshKey = "/root/.ssh/nixbuilder";
        maxJobs = 10; # I have 24 threads
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

  # Nightly flake update
  system.autoUpgrade = {
    enable = true;
    flake = inputs.self.outPath;
    dates = "04:00";
    allowReboot = false;
  };

  # Helpful CLI tools
  environment.systemPackages = with pkgs; [
    tailscale
    vim
    wget
    curl
    git
    htop
    lsof
    tree
    unzip
    zip
    rsync
    neofetch
    bat
    eza
    fd
    ripgrep
    nmap
    nettools
    tcpdump
    iotop
    nethogs
    ncdu
    which
    file
    strace
    niv
  ];
}
