{ config, pkgs, ... }:

{
  networking.hostName = "nixos-cm3588";
  time.timeZone = "America/Los_Angeles";


  environment.systemPackages = with pkgs; [
    vim wget curl git htop lsof tree
    unzip zip rsync neofetch bat eza fd ripgrep
    nmap nettools tcpdump iotop nethogs ncdu
    which file strace
  ];

  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  nix.gc.automatic = true;
  nix.gc.dates = "weekly";
  nix.gc.options = "--delete-older-than 30d";
}
