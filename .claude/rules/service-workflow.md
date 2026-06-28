# Service Workflow

When adding or modifying a service on this NixOS system, follow this exact workflow. Do not skip steps.

## Adding a new service

### Step 1: Decide native vs container

- Check if a NixOS module exists: search.nixos.org/options for "services.SERVICENAME" or grep nixpkgs source
- If a native module exists with the options you need → use it (modules/services/NAME.nix)
- If no native module OR the package is not in nixpkgs → use Podman container (modules/services/pods/NAME.nix)
- NEVER use Docker Compose, docker run scripts, or imperative setup

### Step 2: Register in constants.nix

Every service gets an entry in constants.nix FIRST:

```nix
myservice = {
  port = PICK_UNUSED_PORT;       # check existing entries to avoid conflicts
  hostname = "myservice.home";   # only if it needs a web UI reverse-proxied by nginx
  description = "What it does";
  systemUser = true/false;       # true = auto-create system user in users.nix
};
```

Port allocation: check all existing port values in constants.nix before picking one. Avoid: 3000 (AdGuard), 3001 (Immich), 8096 (Jellyfin), 8080 (WebDAV), 5055 (Jellyseerr).

### Step 3: Create the module file

- Native: modules/services/NAME.nix
- Container: modules/services/pods/NAME.nix

No imports needed — configuration.nix auto-discovers all .nix files under modules/.

For containers, always include:
- systemd.tmpfiles.rules for state directories
- virtualisation.oci-containers.containers.NAME with:
  - image, autoStart, environment (at minimum TZ = config.time.timeZone)
  - ports mapping from constants
  - volumes for persistent state
  - extraOptions with --label=io.containers.autoupdate=registry

### Step 4: Build and test

```bash
rebuild-test    # activates without making it the boot default
```

If build fails:
- Read the FULL error. NixOS errors point to the exact option/type mismatch.
- "infinite recursion" = you used bare if instead of mkIf
- "attribute 'foo' missing" = the option doesn't exist (verify step!)
- "value is a string while a list was expected" = type mismatch (check option type)

### Step 5: Verify the service is running

```bash
systemctl status SERVICE_NAME
journalctl -u SERVICE_NAME --no-pager -n 50
```

For containers:
```bash
sudo podman ps
sudo podman logs CONTAINER_NAME
```

### Step 6: Only then commit

After the service is confirmed running, commit. Not before.

## Modifying an existing service

1. Read the current module file first
2. Check what options are available (verify step from nix-verify rule)
3. Make the change
4. rebuild-test
5. Verify the service still works (systemctl status, check logs for errors)
6. Commit

## Permissions for containers

If a container needs to write to /data/media or other shared storage:
- Add ACL rules in modules/system/storage.nix inside the setup-media-acls service
- Always guard with [ -d /path ] before chmod/chown
- Container UIDs that don't match the media group need explicit user ACLs via setfacl
