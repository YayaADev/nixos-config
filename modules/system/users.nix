{ config, pkgs, ... }:
let
  envVars = import ../../envVars.nix;
in
{
  users.users.nixos = {
    isNormalUser = true;
    extraGroups = [ "wheel" "networkmanager" ];
    shell = pkgs.zsh;
    openssh.authorizedKeys.keys = envVars.sshKeys;
  };

  users.users.cloudflared = {
    isSystemUser = true;
    description = "Cloudflared service user";
    group = "cloudflared";
  };

  security.sudo.wheelNeedsPassword = false;
}