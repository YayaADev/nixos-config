{
  config,
  pkgs,
  serviceHelpers,
  ...
}: let
  constants = import ../../constants.nix;
  serviceConfig = constants.services.audiobookshelf;
in {
  services.audiobookshelf = {
    enable = true;
    port = serviceConfig.port;
    openFirewall = true;
    host = "0.0.0.0";
  };
}
