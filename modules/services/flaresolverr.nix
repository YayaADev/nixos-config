{serviceHelpers, ...}: let
  constants = import ../../constants.nix;
  serviceConfig = constants.services.flaresolverr;
in {
  services.flaresolverr = {
    enable = true;
    openFirewall = false;
    inherit (serviceConfig) port;
  };

  systemd.services.flaresolverr = {
    serviceConfig = {
      User = "flaresolverr";
      Group = "flaresolverr";
      RuntimeDirectory = "flaresolverr";
      StateDirectory = "flaresolverr";
    };
  };

  systemd.tmpfiles.rules = serviceHelpers.createServiceDirectories "flaresolverr" serviceConfig;
}
