{ config, pkgs, lib, ... }:
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

  users.groups.cloudflared = {};

  # Media service users
  users.users.jellyfin = {
    isSystemUser = true;
    description = "Jellyfin Media Server";
    group = "jellyfin";
    extraGroups = [ "video" "render" "users" ];
  };

  users.groups.jellyfin = {};

  users.users.sonarr = {
    isSystemUser = true;
    description = "Sonarr TV Series Manager";
    group = "sonarr";
    extraGroups = [ "users" ];
    home = lib.mkForce "/var/lib/sonarr";
    createHome = true;
  };

  users.groups.sonarr = {};

  users.users.radarr = {
    isSystemUser = true;
    description = "Radarr Movie Manager";
    group = "radarr";
    extraGroups = [ "users" ];
    home = lib.mkForce "/var/lib/radarr";
    createHome = true;
  };

  users.groups.radarr = {};

  users.users.prowlarr = {
    isSystemUser = true;
    description = "Prowlarr Indexer Manager";
    group = "prowlarr";
    home = lib.mkForce "/var/lib/prowlarr";
    createHome = true;
  };

  users.groups.prowlarr = {};

  users.users.bazarr = {
    isSystemUser = true;
    description = "Bazarr Subtitle Manager";
    group = "bazarr";
    extraGroups = [ "users" ];
    home = lib.mkForce "/var/lib/bazarr";
    createHome = true;
  };

  users.groups.bazarr = {};

  users.users.flaresolverr = {
    isSystemUser = true;
    description = "FlareSolverr CloudFlare Solver";
    group = "flaresolverr";
  };

  users.groups.flaresolverr = {};

  security.sudo.wheelNeedsPassword = false;
}