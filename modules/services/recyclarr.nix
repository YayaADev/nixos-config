{
  envVars,
  ...
}:
{
  services.recyclarr = {
    enable = true;
    user = "recyclarr";
    group = "recyclarr";
    schedule = "weekly";

    configuration = {
      radarr = {
        radarr_main = {
          base_url = "http://radarr.home";
          api_key = envVars.radarr.apiKey;
          include = [
            { template = "radarr-quality-definition-movie"; }
            { template = "radarr-custom-formats-hd-bluray-web"; }
            { template = "radarr-quality-profile-hd-bluray-web"; }
            { template = "radarr-custom-formats-uhd-bluray-web"; }
            { template = "radarr-quality-profile-uhd-bluray-web"; }
          ];
          quality_profiles = [
            {
              name = "HD Bluray + WEB";
              reset_unmatched_scores.enabled = true;
              upgrade = {
                allowed = true;
                until_quality = "Bluray-1080p";
                until_score = 10000;
              };
              qualities = [
                {
                  name = "Bluray-1080p";
                  enabled = true;
                }
                {
                  name = "WEBDL-1080p";
                  enabled = true;
                }
                {
                  name = "WEBRip-1080p";
                  enabled = true;
                }
                {
                  name = "Bluray-720p";
                  enabled = true;
                }
              ];
            }
            {
              name = "UHD Bluray + WEB";
              reset_unmatched_scores.enabled = true;
              upgrade = {
                allowed = true;
                until_quality = "Remux-2160p";
                until_score = 10000;
              };
              qualities = [
                {
                  name = "Remux-2160p";
                  enabled = true;
                }
                {
                  name = "Bluray-2160p";
                  enabled = true;
                }
                {
                  name = "WEBDL-2160p";
                  enabled = true;
                }
                {
                  name = "Bluray-1080p";
                  enabled = true;
                }
              ];
            }
          ];
        };
      };

      sonarr = {
        sonarr_main = {
          base_url = "http://sonarr.home";
          api_key = envVars.sonarr.apiKey;

          include = [
            { template = "sonarr-quality-definition-series"; }
            { template = "sonarr-v4-custom-formats-web-1080p"; }
            { template = "sonarr-v4-quality-profile-web-1080p"; }
            { template = "sonarr-v4-custom-formats-web-2160p"; }
            { template = "sonarr-v4-quality-profile-web-2160p"; }
            { template = "sonarr-v4-custom-formats-anime"; }
            { template = "sonarr-v4-quality-profile-anime"; }
          ];

          quality_profiles = [
            {
              name = "WEB-1080p";
              reset_unmatched_scores.enabled = true;
              upgrade = {
                allowed = true;
                until_quality = "WEBDL-1080p";
                until_score = 10000;
              };
              qualities = [
                {
                  name = "WEBDL-1080p";
                  enabled = true;
                }
                {
                  name = "WEBRip-1080p";
                  enabled = true;
                }
                {
                  name = "HDTV-1080p";
                  enabled = true;
                }
              ];
            }
            {
              name = "WEB-2160p";
              reset_unmatched_scores.enabled = true;
              upgrade = {
                allowed = true;
                until_quality = "WEBDL-2160p";
                until_score = 10000;
              };
              qualities = [
                {
                  name = "WEBDL-2160p";
                  enabled = true;
                }
                {
                  name = "WEBRip-2160p";
                  enabled = true;
                }
                {
                  name = "WEBDL-1080p";
                  enabled = true;
                }
              ];
            }
            {
              name = "Remux-1080p - Anime";
              reset_unmatched_scores.enabled = true;
              upgrade = {
                allowed = true;
                until_quality = "Bluray-1080p";
                until_score = 10000;
              };
              qualities = [
                {
                  name = "Bluray-1080p";
                  enabled = true;
                }
                {
                  name = "WEBDL-1080p";
                  enabled = true;
                }
                {
                  name = "Bluray-720p";
                  enabled = true;
                }
              ];
            }
          ];
        };
      };
    };
  };
}
