{
  pkgs,
  inputs,
  ...
}: {
  nix = {
    settings = {
      experimental-features = ["nix-command" "flakes"];
    };

    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 30d";
    };
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
