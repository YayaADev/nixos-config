{
  ...
}:
{
  services.samba = {
    enable = true;
    securityType = "user";
    openFirewall = true;

    settings = {
      global = {
        workgroup = "WORKGROUP";
        "server string" = "CM3588 NAS";
        "netbios name" = "CM3588NAS";
        security = "user";

        # Only allow local network
        "hosts allow" = "192.168.68. 127.0.0.1 localhost";
        "hosts deny" = "0.0.0.0/0";

        # Performance
        "use sendfile" = "yes";

        # macOS/iOS compatibility
        "vfs objects" = "catia fruit streams_xattr";
        "fruit:metadata" = "stream";
        "fruit:model" = "MacSamba";
      };

      # Single share - requires password
      files = {
        path = "/data/Files"; # Change this from /data
        browseable = "yes";
        "read only" = "no";
        "guest ok" = "no";
        "valid users" = "nixos";
        comment = "Files Share";
        "create mask" = "0664";
        "directory mask" = "0775";
        "force user" = "nixos";
        "force group" = "users";
      };
    };
  };

  # Makes your server show up in Windows/iOS network browser
  services.samba-wsdd = {
    enable = true;
    openFirewall = true;
  };

  # Explicitly open firewall ports for Samba
  networking.firewall = {
    allowedTCPPorts = [
      139
      445
    ];
    allowedUDPPorts = [
      137
      138
    ];
  };
}
