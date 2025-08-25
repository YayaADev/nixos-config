{pkgs, ...}: {
  networking.hostName = "nixos-cm3588";
  time.timeZone = "America/Los_Angeles";

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

  nix = {
    settings.experimental-features = ["nix-command" "flakes"];
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 30d";
    };
  };
}
