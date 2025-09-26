{
  config,
  pkgs,
  constants,
  ...
}: {
  services.tailscale = {
    enable = true;
    useRoutingFeatures = "both";
  };

  # Exit node functionality
  networking = {
    firewall = {
      enable = true;
      allowedUDPPorts = [config.services.tailscale.port];
      trustedInterfaces = ["tailscale0"];
      checkReversePath = "loose";
    };
  };

  environment.systemPackages = with pkgs; [
    tailscale
  ];

  # Systemd service for automatic authentication and configuration
  systemd.services.tailscale-autoconnect = {
    description = "Automatic connection to Tailscale with subnet routing";
    after = [
      "network-pre.target"
      "tailscale.service"
    ];
    wants = [
      "network-pre.target"
      "tailscale.service"
    ];
    wantedBy = ["multi-user.target"];
    serviceConfig = {
      Type = "oneshot";
      User = "root";
      RemainAfterExit = true;
    };
    script = ''
      # Wait for tailscaled to settle
      sleep 2

      # Check if we are already authenticated to tailscale
      status="$(${pkgs.tailscale}/bin/tailscale status -json 2>/dev/null | ${pkgs.jq}/bin/jq -r .BackendState 2>/dev/null)" || status="NeedsLogin"

      if [ "$status" = "Running" ]; then
        echo "Tailscale is already running"

        # Use --reset to avoid configuration conflicts
        echo "Re-advertising subnet routes and exit node capability with --reset"
        ${pkgs.tailscale}/bin/tailscale up --reset \
          --advertise-routes=${constants.network.subnet} \
          --advertise-exit-node \
          --accept-routes=true \
          --accept-dns=true \
          --hostname="nixos-home-server" || echo "Failed to update routes, but continuing..."

        exit 0
      fi

      echo "Authenticating with Tailscale using agenix secret"
      ${pkgs.tailscale}/bin/tailscale up \
        --authkey="$(cat ${config.age.secrets.tailscale-authkey.path})" \
        --advertise-routes=${constants.network.subnet} \
        --advertise-exit-node \
        --accept-routes=true \
        --accept-dns=true \
        --hostname="nixos-home-server"
    '';
  };

  # Automatically obtain TLS certificates
  systemd.services.tailscale-cert-renewal = {
    description = "Renew Tailscale TLS certificates";
    serviceConfig = {
      Type = "oneshot";
      User = "root";
    };
    script = ''
      # Get the tailscale machine name
      MACHINE_NAME=$(${pkgs.tailscale}/bin/tailscale status --json 2>/dev/null | ${pkgs.jq}/bin/jq -r '.Self.DNSName' | sed 's/\.$//') 2>/dev/null || echo ""

      if [ -n "$MACHINE_NAME" ]; then
        echo "Obtaining certificate for $MACHINE_NAME"
        ${pkgs.tailscale}/bin/tailscale cert "$MACHINE_NAME" --cert-dir /var/lib/tailscale-certs/ || true
      fi
    '';
  };
}
