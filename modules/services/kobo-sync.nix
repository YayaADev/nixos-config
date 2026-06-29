{constants, ...}: let
  cfg = constants.services.syncthing;
in {
  services.syncthing = {
    enable = true;
    guiAddress = "0.0.0.0:${toString cfg.port}";
    openDefaultPorts = true; # opens 22000/TCP+UDP (sync) and 21027/UDP (LAN discovery)

    overrideDevices = true;
    overrideFolders = false;

    settings = {
      gui = {
        insecure = true;
      };

      options = {
        # Disable global discovery/relay — everything is on Tailscale/LAN
        globalAnnounceEnabled = false;
        relaysEnabled = false;
        localAnnounceEnabled = true;
        urAccepted = -1; # decline usage reporting
      };

      devices = {
        boox-go7 = {
          id = "RVM6OHK-3DLFD37-EXXEE3N-RPSUZHB-MIGZRTL-SPFHY7T-EEWTKVD-FAHOZQW";
          name = "boox-go7";
        };
      };

      folders = {
        kobo = {
          path = "/data/kobo";
          label = "Book Library";
          devices = ["boox-go7"];
          versioning = {
            type = "trashcan";
            params.cleanoutDays = "14";
          };
        };
        boox-koreader-settings = {
          path = "/data/boox-koreader-settings";
          label = "Boox KOReader Settings";
          devices = ["boox-go7"];
        };
      };
    };
  };

  # Pre-create dirs that Syncthing needs to write into, owned by the syncthing user.
  # Without these, any directory created by root (e.g. during setup) blocks Syncthing.
  systemd.tmpfiles.rules = [
    "d /data/boox-koreader-settings 0755 syncthing syncthing -"
    "f /data/boox-koreader-settings/statistics.sqlite3 0644 syncthing syncthing -"
    "d /data/kobo 0755 syncthing syncthing -"
    "d /data/kobo/.adds 0755 syncthing syncthing -"
    "d /data/kobo/.adds/koreader 0755 syncthing syncthing -"
    "d /data/kobo/.adds/koreader/settings 0755 syncthing syncthing -"
    "d /data/kobo/.adds/koreader/plugins 0755 syncthing syncthing -"
    # Recursively fix ownership on the plugins dir (covers files we copied in as root)
    "Z /data/kobo/.adds/koreader/plugins 0755 syncthing syncthing -"
  ];

  # Syncthing web UI port (sync ports are opened by openDefaultPorts above)
  networking.firewall.allowedTCPPorts = [cfg.port];
}
