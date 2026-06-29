#!/usr/bin/env bash
# NixOS CM3588 Home Server — Integration Smoke Test
# Run after nixos-rebuild to verify all services function correctly.
# Usage: sudo ./smoke-test.sh
set -uo pipefail

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[0;33m'; NC='\033[0m'
pass=0; fail=0; warn=0

ok() { printf "${GREEN}PASS${NC}  %s\n" "$1"; pass=$((pass+1)); }
ko() { printf "${RED}FAIL${NC}  %s\n" "$1"; fail=$((fail+1)); }
wo() { printf "${YELLOW}WARN${NC}  %s\n" "$1"; warn=$((warn+1)); }

# Load API keys via nix eval (format-independent, survives reformats)
eval "$(nix eval --impure --expr '
  let e = import /home/nixos/nixos-config/envVars.nix; in
  "export SONARR_KEY=${e.sonarr.apiKey} RADARR_KEY=${e.radarr.apiKey} PROWLARR_KEY=${e.prowlarr.apiKey} BAZARR_KEY=${e.bazarr.apiKey} JELLYFIN_KEY=${e.jellyfin.apiKey}"
' --raw 2>/dev/null)"

SYNCTHING_KEY=$(grep -oP '(?<=<apikey>)[^<]+' /var/lib/syncthing/.config/syncthing/config.xml 2>/dev/null || true)

echo "=== NixOS CM3588 Smoke Test ==="
echo "Timestamp: $(date -Iseconds)"
echo ""

# ============================================================
echo "## 1. Arr Stack — API Health"
echo ""

resp=$(curl -sf -H "X-Api-Key: $SONARR_KEY" http://sonarr.home/api/v3/system/status 2>/dev/null || true)
[[ "$resp" == *'"appName"'* ]] && ok "Sonarr API health" || ko "Sonarr API health"

resp=$(curl -sf -H "X-Api-Key: $RADARR_KEY" http://radarr.home/api/v3/system/status 2>/dev/null || true)
[[ "$resp" == *'"appName"'* ]] && ok "Radarr API health" || ko "Radarr API health"

resp=$(curl -sf -H "X-Api-Key: $PROWLARR_KEY" http://prowlarr.home/api/v1/system/status 2>/dev/null || true)
[[ "$resp" == *'"appName"'* ]] && ok "Prowlarr API health" || ko "Prowlarr API health"

resp=$(curl -sf -H "X-API-KEY: $BAZARR_KEY" http://bazarr.home/api/system/status 2>/dev/null || true)
[[ "$resp" == *'bazarr_version'* ]] && ok "Bazarr API health" || ko "Bazarr API health"

resp=$(curl -sf http://jellyseerr.home/api/v1/status 2>/dev/null || true)
[[ "$resp" == *'"version"'* ]] && ok "Jellyseerr API health" || ko "Jellyseerr API health"

echo ""
# ============================================================
echo "## 2. Arr Stack — Inter-Service Connectivity"
echo ""

resp=$(curl -sf -H "X-Api-Key: $SONARR_KEY" http://sonarr.home/api/v3/downloadclient 2>/dev/null || true)
[[ "$resp" == *'"enable"'*true* ]] && ok "Sonarr → qBittorrent connected" || ko "Sonarr → qBittorrent connected"

resp=$(curl -sf -H "X-Api-Key: $RADARR_KEY" http://radarr.home/api/v3/downloadclient 2>/dev/null || true)
[[ "$resp" == *'"enable"'*true* ]] && ok "Radarr → qBittorrent connected" || ko "Radarr → qBittorrent connected"

resp=$(curl -sf -H "X-Api-Key: $PROWLARR_KEY" http://prowlarr.home/api/v1/applications 2>/dev/null || true)
[[ "$resp" == *'syncLevel'* ]] && ok "Prowlarr → applications syncing" || ko "Prowlarr → applications syncing"

echo ""
# ============================================================
echo "## 3. Media Services — Health"
echo ""

resp=$(curl -sf http://jellyfin.home/health 2>/dev/null || true)
[[ "$resp" == *'Healthy'* ]] && ok "Jellyfin healthy" || ko "Jellyfin healthy"

resp=$(curl -sf http://localhost:8096/System/Info/Public 2>/dev/null || true)
[[ "$resp" == *'"ServerName"'* ]] && ok "Jellyfin system info" || ko "Jellyfin system info"

resp=$(curl -sf http://immich.home/api/server/ping 2>/dev/null || true)
[[ "$resp" == *'pong'* ]] && ok "Immich API pong" || ko "Immich API pong"

# ML container: exit 7 = connection refused = down
curl -sf --connect-timeout 3 http://127.0.0.1:3003/predict >/dev/null 2>&1; ml_rc=$?
[ "$ml_rc" -ne 7 ] && ok "Immich ML container on :3003" || ko "Immich ML container on :3003"

resp=$(curl -sf http://localhost:13378/healthcheck 2>/dev/null || true)
[[ "$resp" == *'OK'* ]] && ok "Audiobookshelf healthy" || ko "Audiobookshelf healthy"

resp=$(curl -sf http://localhost:8191/health 2>/dev/null || true)
[[ "$resp" == *'"ok"'* ]] && ok "FlareSolverr healthy" || ko "FlareSolverr healthy"

resp=$(curl -sf http://localhost:19999/api/v1/info 2>/dev/null || true)
[[ "$resp" == *'"os_name"'* ]] && ok "Netdata responding" || ko "Netdata responding"

echo ""
# ============================================================
echo "## 4. VPN + Torrent Stack"
echo ""

resp=$(curl -sf http://localhost:8000/v1/openvpn/status 2>/dev/null || true)
[[ "$resp" == *'"running"'* ]] && ok "Gluetun VPN running" || ko "Gluetun VPN running"

host_ip=$(ip -4 addr show end0 2>/dev/null | grep -oP '(?<=inet\s)\d+(\.\d+){3}' | head -1)
vpn_ip=$(curl -sf http://localhost:8000/v1/publicip/ip 2>/dev/null | grep -oP '"public_ip":"[^"]+"' | cut -d'"' -f4)
if [ -n "$vpn_ip" ] && [ "$vpn_ip" != "$host_ip" ]; then
  ok "VPN routes traffic (exit IP: $vpn_ip)"
else
  ko "VPN routes traffic (vpn=${vpn_ip:-none} host=$host_ip)"
fi

code=$(curl -sf -o /dev/null -w '%{http_code}' http://localhost:8090/ 2>/dev/null || true)
[[ "$code" == "200" || "$code" == "401" ]] && ok "qBittorrent WebUI (HTTP $code)" || ko "qBittorrent WebUI (HTTP ${code:-timeout})"

echo ""
# ============================================================
echo "## 5. Container File Access"
echo ""

sudo podman exec qbittorrent-nox sh -c 'touch /data/media/downloads/.smoke && rm /data/media/downloads/.smoke' 2>/dev/null \
  && ok "qBittorrent writes /data/media/downloads" || ko "qBittorrent writes /data/media/downloads"

sudo podman exec chaptarr sh -c 'touch /data/media/books/.smoke && rm /data/media/books/.smoke' 2>/dev/null \
  && ok "Chaptarr writes /data/media/books" || ko "Chaptarr writes /data/media/books"

sudo podman exec tdarr ls /media/movies >/dev/null 2>&1 \
  && ok "Tdarr reads /media/movies" || ko "Tdarr reads /media/movies"

sudo podman exec tdarr test -e /dev/dri/renderD128 2>/dev/null \
  && ok "Tdarr has /dev/dri/renderD128" || ko "Tdarr has /dev/dri/renderD128"

sudo podman exec koshelf ls /books >/dev/null 2>&1 \
  && ok "KoShelf reads /books" || ko "KoShelf reads /books"

sudo podman exec koinsight ls /app/data >/dev/null 2>&1 \
  && ok "KoInsight reads /app/data" || ko "KoInsight reads /app/data"

sudo -u immich sh -c 'touch /data/photos/.smoke && rm /data/photos/.smoke' 2>/dev/null \
  && ok "Immich writes /data/photos" || ko "Immich writes /data/photos"

sudo -u syncthing sh -c 'touch /data/kobo/.smoke && rm /data/kobo/.smoke' 2>/dev/null \
  && ok "Syncthing writes /data/kobo" || ko "Syncthing writes /data/kobo"

echo ""
# ============================================================
echo "## 6. Hardware Acceleration (udev)"
echo ""

[[ "$(stat -c %G /dev/dri/renderD128 2>/dev/null)" == "render" && "$(stat -c %a /dev/dri/renderD128 2>/dev/null)" == "664" ]] \
  && ok "/dev/dri/renderD128 render:664" || ko "/dev/dri/renderD128 render:664"

[[ "$(stat -c %G /dev/rga 2>/dev/null)" == "video" && "$(stat -c %a /dev/rga 2>/dev/null)" == "664" ]] \
  && ok "/dev/rga video:664" || ko "/dev/rga video:664"

if [ -e /dev/mpp_service ]; then
  [[ "$(stat -c %G /dev/mpp_service)" == "video" ]] \
    && ok "/dev/mpp_service video" || ko "/dev/mpp_service video"
fi

echo ""
# ============================================================
echo "## 7. Nginx Reverse Proxy"
echo ""

for host in sonarr.home radarr.home prowlarr.home immich.home jellyseerr.home adguard.home syncthing.home koshelf.home koinsight.home; do
  code=$(curl -sf -o /dev/null -w '%{http_code}' --connect-timeout 3 "http://$host" 2>/dev/null || true)
  if [[ -n "$code" && "$code" -ge 200 && "$code" -lt 400 ]]; then
    ok "$host HTTP $code"
  else
    ko "$host HTTP ${code:-timeout}"
  fi
done

echo ""
# ============================================================
echo "## 8. DNS (AdGuard)"
echo ""

resp=$(curl -sf http://adguard.home/control/status 2>/dev/null || true)
[[ "$resp" == *'"running"'* ]] && ok "AdGuard running" || ko "AdGuard running"

resolved=$(dig +short @127.0.0.1 jellyfin.home 2>/dev/null | tail -1)
[[ "$resolved" == "192.168.68.59" ]] && ok "DNS *.home → 192.168.68.59" || ko "DNS *.home → ${resolved:-empty}"

echo ""
# ============================================================
echo "## 9. Syncthing"
echo ""

resp=$(curl -sf -H "X-API-Key: $SYNCTHING_KEY" http://syncthing.home/rest/system/status 2>/dev/null || true)
[[ "$resp" == *'"myID"'* ]] && ok "Syncthing API responds" || ko "Syncthing API responds"

echo ""
# ============================================================
echo "## 10. Cloudflare Tunnel"
echo ""

systemctl is-active cloudflared >/dev/null 2>&1 && ok "Cloudflared active" || wo "Cloudflared inactive"

resp=$(curl -sf --connect-timeout 10 https://jellyfin.peakmalephysique.dev/health 2>/dev/null || true)
[[ "$resp" == *'Healthy'* ]] && ok "Jellyfin via tunnel" || wo "Tunnel inconclusive"

echo ""
# ============================================================
echo "## 11. Samba"
echo ""

smbclient -L //localhost -N 2>/dev/null | grep -qi 'files' \
  && ok "Samba 'files' share" || ko "Samba 'files' share"

echo ""
# ============================================================
echo "## 12. Btrfs Mounts"
echo ""

mount | grep -q 'on /data type btrfs.*compress=zstd:3' && ok "/data compress=zstd:3" || ko "/data compress=zstd:3"
mount | grep -q 'on /data/media type btrfs.*subvol=/media' && ok "/data/media subvol=media" || ko "/data/media subvol=media"
mount | grep -q 'on /var/lib type btrfs.*subvol=/var-lib' && ok "/var/lib subvol=var-lib" || ko "/var/lib subvol=var-lib"

echo ""
# ============================================================
echo "## 13. Permission Errors (since service restart)"
echo ""

err_found=0
for svc in jellyfin sonarr radarr immich-server podman-tdarr podman-qbittorrent-nox podman-koshelf podman-koinsight podman-unpackerr podman-chaptarr; do
  start_time=$(systemctl show "$svc" --property=ActiveEnterTimestamp --value 2>/dev/null)
  [ -z "$start_time" ] && continue
  count=$(journalctl -u "$svc" --since "$start_time" --no-pager -p err 2>/dev/null | grep -ci 'permission denied\|EACCES\|access denied' || true)
  if [ "$count" -gt 0 ]; then
    ko "$svc — $count permission error(s)"
    err_found=1
  fi
done
[ "$err_found" -eq 0 ] && ok "No permission errors in logs"

echo ""
# ============================================================
echo "## 14. System Health"
echo ""

failed_units=$(systemctl --failed --no-legend 2>/dev/null | grep -cv 'recyclarr\|cloudflared\|mam-dynamic\|nixos-upgrade\|health-check' || true)
[ "$failed_units" -eq 0 ] && ok "No unexpected failed units" || ko "$failed_units unexpected failed unit(s)"

systemctl is-active podman-auto-update.timer >/dev/null 2>&1 && ok "podman-auto-update timer" || ko "podman-auto-update timer"
systemctl is-active setup-media-acls.timer >/dev/null 2>&1 && ok "setup-media-acls timer" || ko "setup-media-acls timer"
systemctl is-active btrfs-scrub.timer >/dev/null 2>&1 && ok "btrfs-scrub timer" || ko "btrfs-scrub timer"

echo ""
echo "=============================="
printf "Results: ${GREEN}%d passed${NC}, ${RED}%d failed${NC}, ${YELLOW}%d warnings${NC}\n" "$pass" "$fail" "$warn"
echo "=============================="
[ "$fail" -eq 0 ] && exit 0 || exit 1
