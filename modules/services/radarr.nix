{serviceHelpers, ...}: let
  constants = import ../../constants.nix;
  serviceConfig = constants.services.radarr;
in {
  services.radarr = {
    enable = true;
    openFirewall = false;
    user = "radarr";
    group = "radarr";
  };

  systemd.tmpfiles.rules = serviceHelpers.createServiceDirectories "radarr" serviceConfig;
}
