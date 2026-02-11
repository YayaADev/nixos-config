{
  serviceHelpers,
  constants,
  ...
}: let
  serviceConfig = constants.services.bazarr;
in {
  services.bazarr = {
    enable = true;
    openFirewall = false;
    user = "bazarr";
    group = "bazarr";
  };

  systemd.tmpfiles.rules = serviceHelpers.createServiceDirectories "bazarr" serviceConfig;
}
