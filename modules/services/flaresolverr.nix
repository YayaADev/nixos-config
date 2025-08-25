{serviceHelpers, ...}: let
  constants = import ../../constants.nix;
  serviceConfig = constants.services.flaresolverr;
in {
  # OPTION 1: Use native NixOS service (try this first)
  services.flaresolverr = {
    enable = true;
    openFirewall = false;
    inherit (serviceConfig) port;
  };

  # Override to use our dedicated user
  systemd.services.flaresolverr = {
    serviceConfig = {
      User = "flaresolverr";
      Group = "flaresolverr";
      RuntimeDirectory = "flaresolverr";
      StateDirectory = "flaresolverr";
    };
  };

  systemd.tmpfiles.rules = serviceHelpers.createServiceDirectories "flaresolverr" serviceConfig;

  # OPTION 2: If native service fails, uncomment this NUR version:
  #
  # services.flaresolverr = {
  #   enable = true;
  #   openFirewall = false;
  #   port = serviceConfig.port;
  #   package = pkgs.nur.repos.xddxdd.flaresolverr-21hsmw;
  # };
}
