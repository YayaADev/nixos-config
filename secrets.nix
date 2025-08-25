let
  envVars = import ./envVars.nix;
in
{
  "secrets/tailscale-authkey.age".publicKeys = [ envVars.hostKey ];
  "secrets/cloudflared-creds.age".publicKeys = [ envVars.hostKey ];
  "secrets/grafana-password.age".publicKeys = [ envVars.hostKey ];
  "secrets/grafana-secret.age".publicKeys = [ envVars.hostKey ];
}