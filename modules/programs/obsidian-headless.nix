# Obsidian headless daemon + CLI
# Runs the Electron app under Xvfb so the `obsidian` CLI works on a headless server.
# The daemon keeps a Unix socket alive; CLI invocations attach to it automatically.
#
# First build will fail with the real hash — copy it from the error and replace lib.fakeHash.
# After rebuild: sudo systemctl enable --now obsidian-headless
{
  pkgs,
  lib,
  ...
}: let
  obsidian = pkgs.appimageTools.wrapType2 {
    name = "obsidian";
    version = "1.8.10";
    src = pkgs.fetchurl {
      url = "https://github.com/obsidianmd/obsidian-releases/releases/download/v1.8.10/Obsidian-1.8.10-arm64.AppImage";
      hash = lib.fakeHash;
    };
  };
in {
  environment.systemPackages = [
    obsidian
    pkgs.xvfb-run
    pkgs.jq
  ];

  systemd.services.obsidian-headless = {
    description = "Obsidian headless daemon (Xvfb)";
    wantedBy = ["multi-user.target"];
    after = ["network.target"];

    preStart = ''
      mkdir -p /home/nixos/.config/obsidian
      cfg=/home/nixos/.config/obsidian/obsidian.json
      if [ ! -f "$cfg" ]; then
        echo '{"cli":true}' > "$cfg"
      else
        tmp=$(mktemp)
        ${pkgs.jq}/bin/jq '.cli = true' "$cfg" > "$tmp" && mv "$tmp" "$cfg"
      fi
    '';

    serviceConfig = {
      User = "nixos";
      Type = "simple";
      Environment = ["HOME=/home/nixos"];
      ExecStart = "${pkgs.xvfb-run}/bin/xvfb-run --auto-servernum -- ${obsidian}/bin/obsidian --disable-gpu --disable-software-rasterizer --vault \"/data/obsidian/Obsidian Vault\"";
      Restart = "on-failure";
      RestartSec = "5s";
    };
  };
}
