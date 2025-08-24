let
  envVars = import ../envVars.nix;
  systemKeys = [ envVars.hostKey ];
in
{
  "tailscale-authkey.age".publicKeys = systemKeys;
  "cloudflared-creds.age".publicKeys = systemKeys;
}