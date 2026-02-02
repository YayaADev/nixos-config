{
  lib,
  serviceHelpers,
  constants,
  ...
}:
let
  serviceConfig = constants.services.jellyseerr;
in
{
  services.jellyseerr = {
    enable = true;
    inherit (serviceConfig) port;
  };

  systemd.services.jellyseerr = {
    serviceConfig = {
      User = lib.mkForce "jellyseerr";
      Group = lib.mkForce "jellyseerr";
      StateDirectory = lib.mkForce "jellyseerr";
    };
  };

  systemd.tmpfiles.rules = serviceHelpers.createServiceDirectories "jellyseerr" serviceConfig;
}
