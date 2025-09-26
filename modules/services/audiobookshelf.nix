{constants, ...}: let
  serviceConfig = constants.services.audiobookshelf;
in {
  services.audiobookshelf = {
    enable = true;
    inherit (serviceConfig) port;
    openFirewall = true;
    host = "0.0.0.0";
  };
}
