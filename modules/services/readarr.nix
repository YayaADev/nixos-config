{serviceHelpers, ...}: let
  constants = import ../../constants.nix;
  serviceConfig = constants.services.readarr;
in {
  services.readarr = {
    enable = true;
    openFirewall = false;
    user = "readarr";
    group = "readarr";
  };

  systemd.tmpfiles.rules = serviceHelpers.createServiceDirectories "readarr" serviceConfig;
}
