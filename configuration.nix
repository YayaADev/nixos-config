{ config, lib, pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ./modules/system/boot.nix 
    ./modules/system/basics.nix
    ./modules/shell/zsh.nix
    ./modules/services/ssh.nix
    ./modules/services/nginx.nix
    ./modules/users/nixos.nix
    ./modules/system/networking.nix
    ./modules/development/vscode.nix
    ./modules/services/adguard.nix
  ];

  system.stateVersion = "25.05";
}
