{ pkgs, lib, ... }:
{
  nixpkgs.config.allowUnfreePredicate = pkg:
    builtins.elem (lib.getName pkg) [ "netdata" ];

  services.netdata = {
    enable = true;
    package = pkgs.netdata.override { withCloudUi = true; };
    config = {
      global = {
        "memory mode" = "dbengine";
        "page cache size" = 32;
        "dbengine multihost disk space" = 256;
      };
    };
  };

  networking.firewall.allowedTCPPorts = [ 19999 ];
}