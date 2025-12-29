{
  envVars,
  ...
}:
let
  user = envVars.userKey;

  nixos-cm3588 = envVars.hostKey;

  allKeys = [
    user
    nixos-cm3588
  ];
in
{
  "secrets/tailscale-authkey.age".publicKeys = allKeys;
  "secrets/cloudflared-creds.age".publicKeys = allKeys;
}
