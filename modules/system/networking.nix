{
  constants,
  pkgs,
  ...
}:
{
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

  # Tell networkd: use DHCP for IP only, ignore its DNS. it keep sgetting overritten its annoying
  systemd.network.networks."10-${constants.network.interface}" = {
    matchConfig.Name = constants.network.interface;
    networkConfig.DHCP = "ipv4";
    dhcpV4Config.UseDNS = false;
  };

  networking.firewall = {
    allowedTCPPorts = constants.allTcpPorts;
  };

  environment.systemPackages = with pkgs; [
    nmap
    arp-scan
  ];
}
