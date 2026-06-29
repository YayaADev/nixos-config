{pkgs, ...}: {
  virtualisation = {
    containers.enable = true;
    podman = {
      enable = true;
      dockerCompat = true;
      defaultNetwork.settings.dns_enabled = false;
      autoPrune = {
        enable = true;
        flags = ["--all"];
        dates = "weekly";
      };
    };
    oci-containers.backend = "podman";
  };

  systemd.timers.podman-auto-update = {
    description = "Podman auto-update timer";
    timerConfig = {
      OnCalendar = "Mon 02:00";
      Persistent = true;
    };
    wantedBy = ["timers.target"];
  };

  systemd.services.podman-auto-update = {
    description = "Podman auto-update service";
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.podman}/bin/podman auto-update --rollback";
    };
    after = ["network-online.target"];
    wants = ["network-online.target"];
  };

  systemd.timers.podman-network-prune = {
    description = "Prune unused podman networks weekly";
    timerConfig = {
      OnCalendar = "Sun 03:00";
      Persistent = true;
    };
    wantedBy = ["timers.target"];
  };

  systemd.services.podman-network-prune = {
    description = "Prune unused podman networks";
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.podman}/bin/podman network prune -f";
    };
  };
}
