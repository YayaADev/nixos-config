# NixOS Home Server Configuration

My NixOS configuration for a home server running on FriendlyElec CM3588+ SBC.

## Overview

Self-hosted media and services infrastructure on FriendlyElec CM3588+ with Podman containerization.

- **Media Management**: Complete *arr stack (Sonarr, Radarr, Prowlarr, Bazarr) + Jellyfin media server
- **Request Management**: Jellyseerr (TV/movies), Shelfarr (books/audiobooks)
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
| **Prowlarr** | 9696 | `prowlarr.home` | Indexer management |
| **Bazarr** | 6767 | `bazarr.home` | Subtitle management |
| **qBittorrent** | 8090 | `qbittorrent.home` | Client (VPN binded) |
| **Audiobookshelf** | 13378 | `audiobookshelf.home` | Audiobook server |

### Other Services
| Service | Port | Internal URL | Purpose | Type |
|---------|------|--------------|---------|------|
| **Immich** | 3001 | `immich.home` | Photo management & AI | Podman |
| **Shelfarr** | 5056 | `shelfarr.home` | Book/audiobook request management | Podman |
| **Tdarr** | 8265 | `tdarr.home` | Media transcoding | Podman |
| **WebDAV** | 8080 | `webdav.home` | Obsidian sync server | Native |
| **FlareSolverr** | 8191 | `flaresolverr.home` | Cloudflare bypass | Native |
| **Samba** | 445 | - | SMB file sharing | Native |

### Network & Security
- **Tailscale**: VPN with subnet routing and exit node
- **Cloudflare Tunnel**: Secure external access to Jellyfin and Jellyseerr
- **Podman Auto-Update**: Automatic container updates every Monday 02:00
- **Podman Restart**: Automatic restart of updated containers every Tuesday 02:00

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
  movies/        # qBittorrent staging → Radarr hardlinks to /data/media/movies
  tv/            # qBittorrent staging → Sonarr hardlinks to /data/media/tv
  shelfarr/      # Shelfarr downloads for books & audiobooks
```

### Automatic Maintenance
- **Weekly scrubbing** for data integrity
- **Weekly garbage collection** for Nix store
- **Weekly pruning** of unused Podman networks
- **Automatic compression** via Btrfs zstd:3

## Security Features

### Access Control
- **User Isolation**: Each service runs as dedicated user
- **Group Management**: `media` group for shared file access
- **SSH Keys**: Password authentication disabled
- **Secrets Management**: Encrypted with agenix

### External Access
- **Tailscale**: Secure VPN access to entire network
- **Cloudflare Tunnel**: Encrypted tunnel for select services
- **No Port Forwarding**: Using cloudflare


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
- http://adguard.home
- etc.


### Backup Strategy
- **Configuration**: Git repository (this repo)
- **Media**: Hopefully RAID1 across 3 drives is good
- **Database**: Service-specific backup solutions
- **Snapshots**: Btrfs snapshots (should prolly use this)
