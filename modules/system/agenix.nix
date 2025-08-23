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
  };
}