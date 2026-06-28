{constants, ...}: {
  networking = {
    hostName = "nixos-cm3588";
    useNetworkd = true;
    interfaces.${constants.network.interface}.useDHCP = true;

    firewall = {
      allowedTCPPorts = constants.allTcpPorts;
      trustedInterfaces = ["lo"]; # Trust loopback interface
    };
  };

  # Disable resolvconf — we manage /etc/resolv.conf directly below
  networking.resolvconf.enable = false;

  # This guarantees /etc/resolv.conf exists and points to AdGuard (localhost)
  environment.etc."resolv.conf".text = ''
    nameserver 127.0.0.1
    nameserver 9.9.9.9
    options edns0
  '';

  # Tell networkd: use DHCP for IP only, ignore the router's DNS (prevents overwrite)
  systemd.network.networks."10-${constants.network.interface}" = {
    matchConfig.Name = constants.network.interface;
    networkConfig.DHCP = "ipv4";
    dhcpV4Config.UseDNS = false;
  };
}
