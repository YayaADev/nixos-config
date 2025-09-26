# modules/system/agenix.nix
{ lib, inputs, ... }:
let
  secretsDir = "/home/nixos/nixos-config/secrets"; # not nix friendly cuz its hard coded to my path, nix wants me to do smth with flakes
in {
  age.secrets = {
    tailscale-authkey = {
      file = "${secretsDir}/tailscale-authkey.age";
      owner = "root";
      group = "root";
      mode = "0400";
    };

    cloudflared-creds = {
      file = "${secretsDir}/cloudflared-creds.age";
      owner = "cloudflared";
      group = "cloudflared";
      mode = "0400";
    };

    grafana-password = {
      file = "${secretsDir}/grafana-password.age";
      owner = "grafana";
      group = "grafana";
      mode = "0400";
    };

    grafana-secret = {
      file = "${secretsDir}/grafana-secret.age";
      owner = "grafana";
      group = "grafana";
      mode = "0400";
    };
  };
}
