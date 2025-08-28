{config, ...}: let
  constants = import ../../constants.nix;
  envVars = import ../../envVars.nix;
in {
  services.cloudflared = {
    enable = true;

    tunnels = {
      ${envVars.cloudflaredTunnelId} = {
        credentialsFile = config.age.secrets.cloudflared-creds.path;

        ingress = {
          "jellyfin.peakmalephysique.dev" = "http://localhost:${toString constants.services.jellyfin.port}";
          "requests.peakmalephysique.dev" = "http://localhost:${toString constants.services.jellyseerr.port}";
        };
        default = "http_status:404";
      };
    };
  };
}
