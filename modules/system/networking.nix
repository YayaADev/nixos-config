# modules/system/networking.nix (or wherever this file is)
{ config, lib, pkgs, ... }:
let
  constants = import ../constants.nix;  # Adjust path as needed
in
{
  networking = {
    hostName = "nixos-cm3588";
    # Try static IP first, fall back to DHCP
    useDHCP = false;
    interfaces.${constants.network.interface} = {
      useDHCP = true; # DHCP as fallback
      ipv4.addresses = [{
        address = constants.network.staticIP;
        prefixLength = 22;
      }];
    };
    # Gateway and DNS with fallbacks
    defaultGateway = constants.network.gateway;
    nameservers = [
      "1.1.1.1" # Always works
      "8.8.8.8" # Always works
      constants.network.gateway # Works when on home network
    ];
  };
  
  environment.systemPackages = with pkgs; [
    nmap
    arp-scan
  ];
}