# NixOS Home Server Configuration

My NixOS configuration for a home server running on FriendlyElec CM3588+ SBC.

## Overview

Some services online (when they work)
- **Media Management**: Complete *arr stack + Jellyfin
- **Network Services**: DNS filtering, reverse proxy
- **Monitoring**: None gl
- **Storage**: Btrfs with compression. RAID1 setup across 3 drives
- **Security**: Tailscale VPN, Cloudflare tunnels
- **Development**: VS Code remote support, Nix development tools

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
| **LazyLibrarian** | 5299 | `lazylibrarian.home` | Book management |

### Other Services
| Service | Port | Internal URL | Purpose |
|---------|------|--------------|---------|
| **Immich** | 3001 | `immich.home` | Photo management & AI |
| **WebDAV** | 8080 | `webdav.home` | Obsidian sync server |
| **FlareSolverr** | 8191 | `flaresolverr.home` | Cloudflare bypass |

### Network & Security
- **Tailscale**: VPN with subnet routing and exit node
- **Cloudflare Tunnel**: Secure external access to Jellyfin and Jellyseerr
- **Gluetun**: VPN container for torrent traffic

## Storage Configuration

### Subvolumes
- `media` → `/data/media` (movies, TV, books, audiobooks)
- `photos` → `/data/photos` (Immich storage)  
- `obsidian` → `/data/obsidian` (WebDAV for Obsidian)
- `torrents` → `/data/torrents` (qBittorrent downloads)

### Automatic Maintenance
- **Monthly scrubbing** for data integrity
- **Weekly garbage collection** for Nix store
- **Daily auto-updates** at 4 AM
- **Automatic compression** and deduplication

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
