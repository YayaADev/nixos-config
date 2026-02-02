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
    resolvconf.enable = false;
  };

  # This bypasses network managers and forces the file to exist with these exact contents.
  environment.etc."resolv.conf".text = ''
    nameserver 127.0.0.1
    nameserver 9.9.9.9
    options edns0
  '';

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
    dig
  ];
}
