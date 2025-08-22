{ config, lib, pkgs, ... }:

{
  imports = [

    # System
    ./hardware-configuration.nix
    ./modules/system/boot.nix 
    ./modules/system/basics.nix
    ./modules/users/nixos.nix
    ./modules/system/networking.nix
    
    # Services
    ./modules/services/nginx.nix
    ./modules/services/adguard.nix
    ./modules/users/nixos.nix
    ./modules/system/networking.nix

    # Programs
    ./modules/programs/nix-tools.nix
    ./modules/programs/vscode.nix
    ./modules/programs/zsh.nix
    ./modules/programs/ssh.nix

  ];

  system.stateVersion = "25.05";
}
