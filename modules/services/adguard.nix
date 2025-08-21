# modules/services/adguard.nix
{ config, lib, pkgs, ... }:
let
  constants = import ../constants.nix;  # Adjust path as needed
in
{
  services.adguardhome = {
    enable = true;
    mutableSettings = false;  # Set to false to force NixOS config
    settings = {
      # Web interface
      http = {
        address = "0.0.0.0:${toString constants.ports.adguard}";
      };
      
      # DNS configuration
      dns = {
        bind_hosts = [ "0.0.0.0" ];
        port = constants.ports.dns;
        # Upstream DNS servers
        upstream_dns = [
          "9.9.9.9"
          "149.112.112.112"
          "1.1.1.1"
          "1.0.0.1"
        ];
        bootstrap_dns = [
          "8.8.8.8"
          "8.8.4.4"
        ];
        # Performance settings
        cache_size = 4194304;
        upstream_mode = "load_balance";
        # Security
        enable_dnssec = true;
        ratelimit = 30;
      };
      
      # Filtering section
      filtering = {
        protection_enabled = true;
        filtering_enabled = true;
        safebrowsing_enabled = true;
        
        rewrites = [
          {
            domain = constants.hostnames.adguard;
            answer = constants.network.staticIP;
          }
        ];
      };
      
      # Filter lists
      filters = [
        {
          enabled = true;
          url = "https://adguardteam.github.io/AdGuardSDNSFilter/Filters/filter.txt";
          name = "AdGuard DNS filter";
        }
        {
          enabled = true;
          url = "https://adguardteam.github.io/HostlistsRegistry/assets/filter_1.txt";
          name = "AdGuard Base filter";
        }
        {
          enabled = true;
          url = "https://adguardteam.github.io/HostlistsRegistry/assets/filter_3.txt";
          name = "AdGuard Tracking Protection filter";
        }
        {
          enabled = true;
          url = "https://adguardteam.github.io/HostlistsRegistry/assets/filter_9.txt";
          name = "Malware Blocklist";
        }
      ];
      
      querylog.enabled = true;
      statistics.enabled = true;
    };
  };

  # Firewall
  networking.firewall = {
    allowedTCPPorts = [ constants.ports.adguard constants.ports.dns ];
    allowedUDPPorts = [ constants.ports.dns ];
  };
}