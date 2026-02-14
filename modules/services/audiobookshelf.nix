{constants, ...}: let
  cfg = constants.services.audiobookshelf;
in {
  services.audiobookshelf = {
    enable = true;
    inherit (cfg) port;
    openFirewall = true;
    host = "0.0.0.0";
  };
}
