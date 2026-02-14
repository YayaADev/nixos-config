# modules/podman-base.nix
# https://nixcademy.com/posts/auto-update-containers/
{
  lib,
  pkgs,
  ...
}: {
  # Podman Core Configuration
  virtualisation = {
    containers.enable = true;
    podman = {
      enable = true;
      dockerCompat = true;
      # DISABLE internal DNS - conflicts with AdGuard on port 53
      defaultNetwork.settings.dns_enabled = false;
      autoPrune = {
        enable = true;
        flags = ["--all"];
        dates = "weekly";
      };
    };
    oci-containers.backend = "podman";
  };

  virtualisation.oci-containers.containers = lib.mkDefault {};

  # Auto Update
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
      ExecStart = "${pkgs.podman}/bin/podman auto-update";
    };
    after = ["network-online.target"];
    wants = ["network-online.target"];
  };

  # Restart Updated Containers
  systemd.timers.podman-restart-updated = {
    description = "Restart updated podman containers";
    timerConfig = {
      OnCalendar = "Tue 02:00";
      Persistent = true;
    };
    wantedBy = ["timers.target"];
  };

  systemd.services.podman-restart-updated = {
    description = "Restart containers that were updated";
    serviceConfig = {
      Type = "oneshot";
      ExecStart = pkgs.writeShellScript "podman-restart-updated" ''
        for service in $(${pkgs.systemd}/bin/systemctl list-units --type=service --all | grep 'podman-.*\.service' | awk '{print $1}'); do
          echo "Restarting $service"
          ${pkgs.systemd}/bin/systemctl try-restart "$service" || true
        done
      '';
    };
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
