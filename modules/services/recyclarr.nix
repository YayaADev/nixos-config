{pkgs, ...}: let
  envVars = import ../../envVars.nix;
in {
  services.recyclarr = {
    enable = true;
    user = "recyclarr";
    group = "recyclarr";
    schedule = "weekly";

    # Recyclarr v5+ configuration
    configuration = {
      radarr = {
        radarr_main = {
          base_url = "http://radarr.home";
          api_key = envVars.radarr.apiKey;
          include = [
            {template = "radarr-quality-definition-movie";}
            {template = "radarr-custom-formats-hd-bluray-web";}
            {template = "radarr-quality-profile-hd-bluray-web";}
            {template = "radarr-custom-formats-uhd-bluray-web";}
            {template = "radarr-quality-profile-uhd-bluray-web";}
          ];
          quality_profiles = [
            {
              name = "HD Bluray + WEB";
              reset_unmatched_scores = {
                enabled = true;
              };
            }
            {
              name = "UHD Bluray + WEB";
              reset_unmatched_scores = {
                enabled = true;
              };
            }
          ];
        };
      };

      sonarr = {
        sonarr_main = {
          base_url = "http://sonarr.home";
          api_key = envVars.sonarr.apiKey;
          include = [
            {template = "sonarr-quality-definition-series";}
            {template = "sonarr-v4-custom-formats-web-1080p";}
            {template = "sonarr-v4-quality-profile-web-1080p";}
            {template = "sonarr-v4-custom-formats-web-2160p";}
            {template = "sonarr-v4-quality-profile-web-2160p";}
          ];
          quality_profiles = [
            {
              name = "WEB-1080p";
              reset_unmatched_scores = {
                enabled = true;
              };
            }
            {
              name = "WEB-4K";
              reset_unmatched_scores = {
                enabled = true;
              };
            }
          ];
        };
      };
    };
  };

  environment.systemPackages = with pkgs; [
    recyclarr
  ];
}
