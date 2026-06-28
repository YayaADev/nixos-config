# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Critical: Verify Before Writing Nix

AI models hallucinate NixOS options constantly. Before writing or suggesting any NixOS module option, service configuration, or package attribute:

1. **Search options first**: Use `nix eval` or check search.nixos.org/options mentally. If uncertain about an option name, shape, or type — look it up.
2. **Never guess option names**: `services.foo.bar` might not exist. The NixOS module system is typed — wrong options cause eval errors, not silent failures.
3. **Never guess package attribute paths**: Check `nix search nixpkgs#foo` or the nixpkgs manual.
4. **When in doubt, fetch docs**: Use WebFetch on the canonical sources below rather than guessing.

## NixOS Documentation Hierarchy (Canonical Sources)

When you need to verify an option, understand a module, or check Nix language semantics:

| Source | URL | Use for |
|--------|-----|---------|
| Nix Reference Manual | nix.dev/reference/nix-manual.html | CLI flags, builtins, nix.conf, language semantics |
| NixOS Manual | nixos.org/manual/nixos/stable/ | Module system, NixOS configuration, system options |
| Nixpkgs Manual | nixos.org/manual/nixpkgs/stable/ | stdenv, fetchers, derivations, package writing |
| NixOS Wiki (official) | wiki.nixos.org | Guides, examples, troubleshooting |
| NixOS Options Search | search.nixos.org/options | Find and verify option names/types |
| NixOS Packages Search | search.nixos.org/packages | Find package attribute paths |
| Nix language tutorial | nix.dev/tutorials/nix-language.html | Syntax, lazy evaluation, patterns |
| Home Manager options | nix-community.github.io/home-manager/options.xhtml | HM option reference |

**Avoid**: The old `nixos.wiki` (no `wiki.` prefix) — community-run, often stale. Always prefer `wiki.nixos.org`.

**Outdated patterns to never use**:
- `nix-env -i` (use declarative config or `nix profile`)
- `nix-shell` for dev environments (use `nix develop` with flakes)
- Nix Pills as a how-to guide (conceptual only, predates flakes)

## Development Philosophy

This is a **NixOS system** running on a FriendlyElec CM3588 (RK3588 ARM). All solutions must follow the NixOS-native way:

- **Always prefer native NixOS service modules** (`services.foo.enable = true`) over any other approach
- **Fall back to Podman OCI containers** (under `modules/services/pods/`) only when no NixOS/nixpkgs module exists
- Never suggest Docker Compose, raw shell scripts, or non-declarative workarounds
- Follow best Nix practices: no `pkgs.runCommand` hacks, proper `_module.args`, use `lib` functions, avoid string concatenation for paths
- All config must be reproducible — if it cannot survive a `nixos-rebuild switch`, it is wrong
- **Flakes are the standard** — this repo uses a flake. Never suggest channel-based or non-flake approaches.

## Build & Deploy Commands

Shell aliases defined in `modules/programs/zsh.nix`:

```bash
rebuild              # nixos-rebuild switch (local, --impure, no remote builder)
rebuild-test         # nixos-rebuild test
rebuild-boot         # nixos-rebuild boot
rebuild-dry          # nixos-rebuild dry-run
rebuild-remote       # nixos-rebuild switch (offload to x86 builder via SSH)
flake-update         # nix flake update
flake-check          # nix flake check --keep-going --impure
rollback             # nixos-rebuild switch --rollback
nix-gc               # nix-collect-garbage -d
```

All rebuilds pass `--impure` (envVars.nix uses an absolute path) and `--flake /home/nixos/nixos-config`.

## Code Quality

Pre-commit hook (`.githooks/pre-commit`) runs on staged `.nix` files:
- **alejandra** — formatter
- **deadnix** — removes dead bindings
- **statix** — fixes anti-patterns

These resolve from PATH (system packages). No `nix develop` needed on this server.

Manual: `alejandra .`, `deadnix -e .`, `statix check .`

## Architecture

### Module Auto-Discovery

`configuration.nix` automatically imports every `.nix` file under `modules/` recursively — no explicit imports needed when adding new modules.

### Central Constants Registry (`constants.nix`)

Single source of truth for all service definitions. Each service entry specifies port, hostname, description, system user requirements, extra groups, and home directory. This feeds:
- `modules/system/users.nix` — auto-generates system users/groups
- `modules/services/nginx.nix` — auto-generates reverse proxy virtual hosts
- `modules/system/storage.nix` — sets up directory permissions
- `modules/system/networking.nix` — auto-opens firewall ports

**When adding a new service**, define it in `constants.nix` first, then create a module in `modules/services/`.

### Service Helper Library (`modules/lib.nix`)

Provides helper functions available to all modules via `_module.args`:
- `createServiceDirectories` / `createAllServiceDirectories`
- `createNginxVirtualHost` / `createAllNginxVirtualHosts`
- `createFirewallRules` / `createAllFirewallRules`

### Service Deployment Patterns

**Native NixOS services** (`modules/services/*.nix`): jellyfin, sonarr, radarr, prowlarr, bazarr, adguard, cloudflared, audiobookshelf, netdata, syncthing, etc.

**Podman containers** (`modules/services/pods/`): immich, chaptarr, koshelf, koinsight, qBittorrent+Gluetun, tdarr, unpackerr, quartz

**Pattern for new container** (`modules/services/pods/foo.nix`):
```nix
{config, constants, ...}: let
  cfg = constants.services.foo;
in {
  systemd.tmpfiles.rules = ["d /var/lib/foo 0755 UID GID -"];

  virtualisation.oci-containers.containers.foo = {
    image = "registry/image:tag";
    autoStart = true;
    environment = { TZ = config.time.timeZone; };
    ports = ["${toString cfg.port}:INTERNAL_PORT"];
    volumes = ["/var/lib/foo:/data"];
    extraOptions = [
      "--label=io.containers.autoupdate=registry"
    ];
  };
}
```

### Systemd Timers
- **Monday 02:00**: `podman-auto-update` — pulls latest container images
- **Tuesday 02:00**: `podman-restart-updated` — restarts updated containers
- **Wednesday 03:00**: `setup-media-acls` — refreshes storage ACLs
- **Sunday 03:00**: `podman-network-prune` — prunes unused networks

### Secrets

- **Agenix**: encrypted `.age` files in `secrets/` (git-ignored). Public keys in `secrets.nix`.
- **envVars.nix**: plaintext secrets/IPs (git-ignored). Template at `envVarsTemplate.nix`.

### Storage

**Hardware:** 4x NVMe SSDs in Btrfs RAID1 (~4.5TB usable). OS on 56GB eMMC.

| Mount | Subvolume | Notes |
|-------|-----------|-------|
| `/data` | `subvol=/` | Root; kobo, tdarr_cache |
| `/data/media` | `subvol=media` | Video + downloads — hardlinks work here |
| `/data/photos` | `subvol=photos` | Immich |
| `/data/obsidian` | `subvol=obsidian` | WebDAV notes |

**Critical:** `/data` and `/data/media` are different subvolumes. Hardlinks cannot cross them. Downloads must live inside `/data/media/downloads/` for *arr hardlinking to work.

**Never use `nocompress` as a Btrfs mount option** — it is not valid and causes boot failure. All volumes use `compress=zstd:3`.

### Permissions

ACL-based. Services in `media` group (GID 980). Containers with fixed UIDs get explicit ACLs via `setup-media-acls` systemd service. Always guard `chmod`/`chown` with `[ -d /path ]` checks for dirs that may not exist yet.

## Key Files

| File | Purpose |
|------|---------|
| `flake.nix` | Inputs: nixpkgs-unstable, nixos-friendlyelec-cm3588, agenix, treefmt-nix |
| `constants.nix` | Service registry — ports, hostnames, user config |
| `envVars.nix` | Network config, API keys, credentials (git-ignored) |
| `configuration.nix` | Top-level system config, auto-imports all modules |
| `modules/lib.nix` | Shared helper functions for service modules |
| `modules/services/pods/podman-base.nix` | Core Podman infrastructure |
| `hardware-configuration.nix` | Auto-generated (do not edit) |
| `.githooks/pre-commit` | Linting hook (alejandra, deadnix, statix) |
