{ config, lib, pkgs, ... }:

{
  imports = [
    "${(import ./nix/sources.nix).agenix}/modules/age.nix"

    # System
    ./hardware-configuration.nix
    ./modules/system/boot.nix 
    ./modules/system/basics.nix
    ./modules/users/nixos.nix
    ./modules/system/networking.nix
    ./modules/system/agenix.nix
    ./modules/system/storage.nix

    # Services
    ./modules/services/nginx.nix
    ./modules/services/adguard.nix
    ./modules/users/nixos.nix
    ./modules/system/networking.nix
    ./modules/services/jellyfin.nix 
    ./modules/services/cloudflared.nix
    
    # Programs
    ./modules/programs/nix-tools.nix
    ./modules/programs/vscode.nix
    ./modules/programs/zsh.nix
    ./modules/programs/ssh.nix
    ./modules/programs/tailscale.nix
  ];

    environment.systemPackages = with pkgs; [
    (pkgs.callPackage "${(import ./nix/sources.nix).agenix}/pkgs/agenix.nix" {})
  ];

  system.stateVersion = "25.05";
}
