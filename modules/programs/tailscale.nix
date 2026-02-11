{
  config,
  constants,
  ...
}: {
  services.tailscale = {
    enable = true;
    useRoutingFeatures = "both";
    authKeyFile = config.age.secrets.tailscale-authkey.path;
    extraUpFlags = [
      "--advertise-routes=${constants.network.subnet}"
      "--advertise-exit-node"
      "--accept-routes=true"
      "--accept-dns=false"
      "--hostname=nixos-home-server"
    ];
  };

  networking.nftables.enable = true;

  networking.firewall = {
    enable = true;
    allowedUDPPorts = [config.services.tailscale.port];
    trustedInterfaces = ["tailscale0"];
    checkReversePath = "loose";
  };

  systemd.services.tailscaled.serviceConfig.Environment = [
    "TS_DEBUG_FIREWALL_MODE=nftables"
  ];
}
