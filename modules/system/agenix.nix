{ config, lib, pkgs, ... }:

# Secrets encrypted with agenix
{
  age.secrets = {
    tailscale-authkey = {
      file = ../../secrets/tailscale-authkey.age;
      owner = "root";
      group = "root";
      mode = "0400";
    };

  cloudflared-creds = {
      file = ../../secrets/cloudflared-creds.age;
      owner = "cloudflared";
      group = "cloudflared";
      mode = "0400";
    };
  };

  age.identityPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
}