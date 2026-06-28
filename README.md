# NixOS Home Server Configuration

My NixOS configuration for a home server running on FriendlyElec CM3588+ SBC.

## Overview

Self-hosted media and services infrastructure on FriendlyElec CM3588+ with Podman containerization.

- **Media Management**: Complete *arr stack (Sonarr, Radarr, Chaptarr, Prowlarr, Bazarr) + Jellyfin media server
- **Request Management**: Jellyseerr (TV/movies)
- **Network Services**: DNS filtering (AdGuard), reverse proxy (Nginx), VPN (Tailscale, Cloudflare)
- **Storage**: Btrfs RAID1 across 3 NVMe SSDs (~3.6TB usable)
- **Containerization**: Podman infrastructure with auto-update timers
- **Photo Management**: Immich with AI features
- **File Sharing**: Samba file server
- **Security**: Tailscale VPN, Cloudflare tunnels, agenix secrets management

## Services Overview

### Network Infrastructure
| Service | Port | Internal URL | Purpose |
|---------|------|--------------|---------|
| **AdGuard Home** | 3000 | `adguard.home` | DNS filtering & ad blocking |
| **Nginx** | 80 | - | Reverse proxy for all services |

### Media Stack
| Service | Port | Internal URL | Purpose |
|---------|------|--------------|---------|
| **Jellyfin** | 8096 | `jellyfin.home` | Media server  |
| **Jellyseerr** | 5055 | `jellyseerr.home` | Media request management |
| **Sonarr** | 8989 | `sonarr.home` | TV series management |
| **Radarr** | 7878 | `radarr.home` | Movie management |
| **Chaptarr** | 8789 | `chaptarr.home` | Ebook/audiobook management (Readarr fork) |
| **Prowlarr** | 9696 | `prowlarr.home` | Indexer management |
| **Bazarr** | 6767 | `bazarr.home` | Subtitle management |
| **qBittorrent** | 8090 | `qbittorrent.home` | Torrent client (VPN via Gluetun, auto port-forward) |
| **Audiobookshelf** | 13378 | `audiobookshelf.home` | Audiobook server |

### Other Services
| Service | Port | Internal URL | Purpose | Type |
|---------|------|--------------|---------|------|
| **Immich** | 3001 | `immich.home` | Photo management with AI | Podman |
| **Tdarr** | 8265 | `tdarr.home` | Media transcoding (GPU-accelerated) | Podman |
| **Unpackerr** | - | - | Archive extraction & import automation | Podman |
| **Gluetun** | 8000 | - | VPN tunnel (ProtonVPN) for qBittorrent | Podman |
| **WebDAV** | 8080 | `webdav.home` | Obsidian sync (HTTP Basic Auth, HTTPS via Cloudflare) | Native |
| **FlareSolverr** | 8191 | `flaresolverr.home` | Cloudflare bypass | Native |
| **Samba** | 445 | - | SMB file sharing | Native |
| **KoInsight** | 3002 | `koinsight.home` | KOReader reading stats + kosync position-sync server | Podman |
| **KoShelf** | 3003 | `koshelf.home` | KOReader highlights/annotations dashboard | Podman |
| **Syncthing** | 8384 | `syncthing.home` | Kobo ↔ NAS file sync (books + .sdr sidecars) | Native |

### Network & Security
- **Tailscale**: VPN with subnet routing and exit node
- **Cloudflare Tunnel**: Secure external access to Jellyfin, Jellyseerr, and WebDAV
- **qBittorrent**: ProtonVPN via Gluetun with automatic port forwarding
- **Podman Timers**:
  - Monday 02:00: Auto-update container images
  - Tuesday 02:00: Restart updated containers
  - Wednesday 03:00: Verify/refresh storage ACLs
  - Sunday 03:00: Prune unused Podman networks

## Storage Configuration

### Hardware
- **3× NVMe SSDs** (2× 1.8TB + 1× 3.6TB) in Btrfs RAID1 = ~3.6TB usable
- **56GB eMMC** for OS and service state (`/`, `/var/lib/`)
- **All data** on SSDs: `/data` and its subvolumes

### Btrfs Subvolumes & Compression
| Mount | Subvolume | Compression | Contents |
|-------|-----------|-------------|----------|
| `/data` | `/` | `zstd:3` | Root, torrents staging |
| `/data/media` | `media` | `zstd:3` | Movies, TV, books, audiobooks |
| `/data/media/downloads` | (same as media) | `zstd:3` | Torrent/request staging |
| `/data/photos` | `photos` | `zstd:3` | Immich photos & RAW files |
| `/data/obsidian` | `obsidian` | `zstd:3` | Obsidian notes |

**Critical:** `/data` and `/data/media` are different subvolumes. Services that hardlink files must operate within the same subvolume.

### Media Download Layout
```
/data/media/downloads/
  movies/              # qBittorrent staging → Radarr hardlinks to /data/media/movies
  tv/                  # qBittorrent staging → Sonarr hardlinks to /data/media/tv
  chaptarr-ebooks/     # qBittorrent staging → Chaptarr hardlinks to /data/media/books
  chaptarr-audiobooks/ # qBittorrent staging → Chaptarr hardlinks to /data/media/audiobooks
```

### Automatic Maintenance
- **Monthly Btrfs scrub** (via `btrfs-scrub` service)
- **Weekly ACL refresh** (Wednesday 03:00 — `setup-media-acls` timer)
- **Weekly garbage collection** for Nix store (`nix-gc` alias)
- **Weekly Podman cleanup** (Sunday 03:00 — prunes unused networks & containers)
- **Weekly container updates** (Monday/Tuesday cycle)
- **Automatic compression** via Btrfs zstd:3

## Security Features

### Access Control
- **User Isolation**: Each service runs as dedicated user/group
- **ACL-Based Permissions**: Fine-grained file access via Linux ACLs
  - Media group (GID 980) for most services
  - Per-service ACLs for containerized apps without proper group membership
  - Tdarr: GPU device access via udev rules
- **SSH Keys**: Password authentication disabled
- **Secrets Management**: Encrypted with agenix

### External Access
- **Tailscale**: Secure VPN access to entire network
- **Cloudflare Tunnel**: Encrypted tunnel for Jellyfin, Jellyseerr, WebDAV
- **WebDAV**: HTTP Basic Auth + client-side E2E encryption for Obsidian notes
- **No Port Forwarding**: Using Cloudflare for remote access


### System Management
```bash
# Update system
rebuild

# Update flake inputs
flake-update

# Check configuration
flake-check

# Rollback changes
rollback

# Clean up old generations
nix-gc
```

### Storage Management
```bash
# Check Btrfs usage
btrfs-usage

# Check scrub status
btrfs-scrub-status

# View subvolumes
btrfs-subvols

# Storage overview
storage-info
```

### Service Management
```bash
# Restart service
sudo systemctl restart jellyfin

# View logs
journalctl -fu jellyfin

# Check service status
systemctl status --all
```

## Network Access

### Internal Access
All services available via `.home` domains:
- http://jellyfin.home
- http://jellyseerr.home
- http://chaptarr.home
- http://adguard.home
- http://webdav.home:8080 (requires Basic Auth)
- etc.

### External Access (via Cloudflare Tunnel)
Select services exposed via HTTPS at `*.peakmalephysique.dev`:
- **Jellyfin**: https://jellyfin.peakmalephysique.dev
- **Jellyseerr**: https://requests.peakmalephysique.dev
- **WebDAV**: https://webdav.peakmalephysique.dev (requires Basic Auth + optional E2E encryption)

### Backup Strategy
- **Configuration**: Git repository (this repo)
- **Media**: Hopefully RAID1 across 3 drives is good
- **Database**: Service-specific backup solutions
- **Snapshots**: Btrfs snapshots (should prolly use this)
