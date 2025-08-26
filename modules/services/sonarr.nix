{serviceHelpers, ...}: let
  constants = import ../../constants.nix;
  serviceConfig = constants.services.sonarr;
in {
  services.sonarr = {
    enable = true;
    openFirewall = false;
    user = "sonarr";
    group = "sonarr";
  };

  systemd.tmpfiles.rules = serviceHelpers.createServiceDirectories "sonarr" serviceConfig;
}
