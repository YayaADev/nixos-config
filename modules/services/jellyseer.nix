{constants, ...}: let
  serviceConfig = constants.services.jellyseerr;
in {
  services.seerr = {
    enable = true;
    inherit (serviceConfig) port;
  };
}
