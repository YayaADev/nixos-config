{pkgs, ...}: let
  constants = import ../../constants.nix;
in {
  networking = {
    hostName = "nixos-cm3588";
    useNetworkd = true;
    interfaces.${constants.network.interface}.useDHCP = true;

    nameservers = [
      constants.network.staticIP
      "9.9.9.9" # Quad9
      "1.1.1.1" # Cloudflare
    ];
  };

  # Open firewall for all service ports
  networking.firewall = {
    allowedTCPPorts = constants.allTcpPorts;
  };

  environment.systemPackages = with pkgs; [
    nmap
    arp-scan
  ];
}
