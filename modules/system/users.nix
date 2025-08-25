{
  pkgs,
  lib,
  ...
}: let
  envVars = import ../../envVars.nix;
  constants = import ../../constants.nix;

  # Function to create a system user for a service
  createUserForSystemService = serviceName: serviceConfig: {
    users.${serviceName} =
      {
        isSystemUser = true;
        inherit (serviceConfig) description;
        group = serviceName;
        extraGroups = serviceConfig.extraGroups or [];
      }
      // lib.optionalAttrs (serviceConfig.createHome or false) {
        home = lib.mkForce (serviceConfig.homeDir or "/var/lib/${serviceName}");
        createHome = true;
      };

    groups.${serviceName} = {};
  };

  # Generate users and groups for all system services
  systemServiceUsers =
    lib.foldlAttrs
    (
      acc: serviceName: serviceConfig:
        if (serviceConfig.systemUser or false)
        then lib.recursiveUpdate acc (createUserForSystemService serviceName serviceConfig)
        else acc
    )
    {
      users = {};
      groups = {};
    }
    constants.services;
in {
  # Regular user accounts
  users.users =
    {
      nixos = {
        isNormalUser = true;
        extraGroups = [
          "wheel"
          "networkmanager"
        ];
        shell = pkgs.zsh;
        openssh.authorizedKeys.keys = envVars.sshKeys;
      };
    }
    // systemServiceUsers.users; # Merge system service users

  # System service groups
  users.groups = systemServiceUsers.groups;

  # Security settings
  security.sudo.wheelNeedsPassword = false;
}
