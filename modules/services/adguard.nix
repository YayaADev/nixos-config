# Adguard wiki https://wiki.nixos.org/wiki/Adguard_Home
{constants, ...}: let
  serviceConfig = constants.services.adguard;
in {
  services.adguardhome = {
    enable = true;
    mutableSettings = true;
    settings = {
      http = {
        address = "0.0.0.0:${toString serviceConfig.port}";
        trusted_proxies = [
          "127.0.0.1"
          "::1"
        ];
      };
      # DNS configuration
      dns = {
        bind_hosts = ["0.0.0.0"];
        port = 53;
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
        cache_size = 4194304;
        upstream_mode = "load_balance";
        enable_dnssec = true;
        ratelimit = 30;
      };

      filtering = {
        protection_enabled = true;
        filtering_enabled = true;
        safebrowsing_enabled = true;
        filters_update_interval = 24;

        rewrites = [
          {
            domain = "*.home";
            answer = constants.network.staticIP;
            enabled = true;
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
        {
          enabled = true;
          url = "https://raw.githubusercontent.com/badmojr/1Hosts/master/Lite/adblock.txt";
          name = "1Hosts (Lite)";
        }
        {
          enabled = true;
          url = "https://raw.githubusercontent.com/hagezi/dns-blocklists/main/adblock/multi.txt";
          name = "Hagezi Personal DNS Blocklist";
        }
        {
          enabled = true;
          url = "https://easylist.to/easylist/easyprivacy.txt";
          name = "EasyPrivacy";
        }
      ];

      querylog = {
        enabled = true;
        interval = "24h";
        size_memory = 1000;
        ignored = [];
      };

      statistics = {
        enabled = true;
        interval = "24h";
        ignored = [];
      };
    };
  };

  # Firewall
  networking.firewall = {
    allowedTCPPorts = [53];
    allowedUDPPorts = [53];
  };
}
