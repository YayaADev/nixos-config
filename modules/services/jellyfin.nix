{
  pkgs,
  serviceHelpers,
  constants,
  ...
}: let
  serviceConfig = constants.services.jellyfin;
in {
  services.jellyfin = {
    enable = true;
    user = "jellyfin";
    group = "jellyfin";
  };

  systemd.tmpfiles.rules =
    serviceHelpers.createServiceDirectories "jellyfin" serviceConfig
    ++ [
      "Z /var/cache/jellyfin 0755 jellyfin jellyfin -"
    ];

  environment.systemPackages = with pkgs; [
    jellyfin
    jellyfin-web
    jellyfin-ffmpeg
  ];
}
