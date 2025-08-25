{lib, ...}: {
  age.secrets = lib.mkIf (builtins.pathExists ../../secrets) {
    tailscale-authkey = lib.mkIf (builtins.pathExists ../../secrets/tailscale-authkey.age) {
      file = ../../secrets/tailscale-authkey.age;
      owner = "root";
      group = "root";
      mode = "0400";
    };

    cloudflared-creds = lib.mkIf (builtins.pathExists ../../secrets/cloudflared-creds.age) {
      file = ../../secrets/cloudflared-creds.age;
      owner = "cloudflared";
      group = "cloudflared";
      mode = "0400";
    };

    grafana-password = lib.mkIf (builtins.pathExists ../../secrets/grafana-password.age) {
      file = ../../secrets/grafana-password.age;
      owner = "grafana";
      group = "grafana";
      mode = "0400";
    };

    grafana-secret = lib.mkIf (builtins.pathExists ../../secrets/grafana-secret.age) {
      file = ../../secrets/grafana-secret.age;
      owner = "grafana";
      group = "grafana";
      mode = "0400";
    };
  };

  age.identityPaths = ["/etc/ssh/ssh_host_ed25519_key"];
}
