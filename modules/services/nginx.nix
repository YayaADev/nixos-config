# Wiki https://nixos.wiki/wiki/Nginx
{ config, lib, pkgs, serviceHelpers, ... }:
let
  constants = import ../../constants.nix;
in
{
  services.nginx = {
    enable = true;
    
    # Automatically create virtual hosts for all services with hostnames
    virtualHosts = serviceHelpers.createAllNginxVirtualHosts 
      constants.network.staticIP 
      constants.nginxServices;
  };
}