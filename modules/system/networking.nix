{ config, lib, pkgs, ... }:
let
  constants = import ../constants.nix;
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
       "9.9.9.9"
       "1.1.1.1" 
      constants.network.staticIP
    ];
  };
  
  environment.systemPackages = with pkgs; [
    nmap
    arp-scan
  ];
}