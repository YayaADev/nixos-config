{
  serviceHelpers,
  constants,
  ...
}: let
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
