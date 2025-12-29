{
  constants,
  pkgs,
  ...
}: {
  networking = {
    hostName = "nixos-cm3588";
    useNetworkd = true;
    interfaces.${constants.network.interface}.useDHCP = true;

    nameservers = [
      "127.0.0.1"
      "9.9.9.9"
      "1.1.1.1"
    ];
  };

  networking.firewall = {
    allowedTCPPorts = constants.allTcpPorts;
  };

  environment.systemPackages = with pkgs; [
    nmap
    arp-scan
  ];
}
