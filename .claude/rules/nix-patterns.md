# Nix Patterns and Anti-Patterns

Correct patterns for this NixOS configuration. Reference when writing or reviewing Nix code.

## Module structure (this repo's convention)

Every module in this repo is a "shorthand" module — no explicit options block, just config values at the top level:

```nix
{config, lib, pkgs, constants, ...}: let
  cfg = constants.services.myservice;
in {
  # Direct config values (shorthand module form)
  services.foo.enable = true;
  services.foo.port = cfg.port;
}
```

We do NOT declare custom options (no options = { } blocks). The constants.nix registry serves that role instead.

## Correct patterns

### Systemd services
```nix
systemd.services.my-task = {
  description = "My scheduled task";
  wantedBy = [ "multi-user.target" ];  # start on boot
  after = [ "network.target" ];
  serviceConfig = {
    Type = "oneshot";       # or "simple" for long-running
    User = "myuser";
    ExecStart = "${pkgs.coreutils}/bin/echo hello";
    # StateDirectory creates /var/lib/my-task owned by User
    StateDirectory = "my-task";
  };
};
```

### Systemd timers
```nix
systemd.timers.my-task = {
  wantedBy = [ "timers.target" ];
  timerConfig = {
    OnCalendar = "daily";        # or "Mon *-*-* 02:00:00"
    Persistent = true;           # run missed executions after downtime
    Unit = "my-task.service";
  };
};
```

For simple cases, use startAt on the service directly (auto-generates timer):
```nix
systemd.services.my-task.startAt = "daily";
```

### Overlays (when needed)
```nix
nixpkgs.overlays = [
  (final: prev: {
    mypackage = prev.mypackage.overrideAttrs (old: {
      patches = (old.patches or []) ++ [ ./my-fix.patch ];
    });
  })
];
```

- Use prev.foo to reference the original package
- Use final.foo to reference the already-overridden version
- NEVER use final.foo to define foo itself (infinite recursion)

### Firewall
Ports are auto-opened from constants.nix via modules/system/networking.nix. For manual additions:
```nix
networking.firewall.allowedTCPPorts = [ 1234 ];
networking.firewall.allowedUDPPorts = [ 5678 ];
```

### tmpfiles (pre-create directories)
```nix
systemd.tmpfiles.rules = [
  "d /var/lib/myservice 0755 user group -"
  "Z /var/lib/myservice 0755 user group -"   # recursive ownership fix
];
```
Format: "type path mode user group age"

## Anti-patterns (never do these)

### WRONG: bare if instead of mkIf
```nix
# CAUSES INFINITE RECURSION
config = if config.services.foo.enable then { ... } else {};
```
FIX: config = lib.mkIf config.services.foo.enable { ... };

### WRONG: nocompress mount option
```nix
# NOT A VALID BTRFS OPTION — causes boot failure
fileSystems."/data".options = [ "nocompress" "noatime" ];
```
FIX: just omit compress if you don't want it. Valid: compress=zstd, compress=zstd:3, compress=lzo, compress=zlib.

### WRONG: string where list expected
```nix
# Type error
environment.systemPackages = "vim";
```
FIX: environment.systemPackages = [ pkgs.vim ];

### WRONG: shallow merge expecting deep merge
```nix
# // only merges top level — nested attrs are REPLACED
{ a = { x = 1; y = 2; }; } // { a = { z = 3; }; }
# Result: { a = { z = 3; }; }  — x and y are GONE
```
FIX: use lib.recursiveUpdate or lib.mkMerge for deep merging

### WRONG: hardcoded store paths
```nix
# These break on nix-collect-garbage
ExecStart = "/nix/store/abc123-foo/bin/foo";
```
FIX: ExecStart = "${pkgs.foo}/bin/foo";

### WRONG: using import for modules
```nix
# import evaluates a file. imports integrates a module.
imports = [ (import ./foo.nix) ];  # sometimes works but wrong semantics
```
FIX: imports = [ ./foo.nix ];

### WRONG: missing ... in module args
```nix
# Fails with "unexpected argument" if NixOS passes extra args
{ config, pkgs }:  # MISSING ...
```
FIX: { config, pkgs, ... }:

## lib functions to prefer

- lib.mkIf — conditional config (never bare if)
- lib.mkMerge — combine multiple config blocks
- lib.mkDefault — low-priority value (overridable)
- lib.mkForce — highest priority (use sparingly)
- lib.optionals bool list — conditional list items
- lib.optionalAttrs bool set — conditional attrset entries
- lib.concatStringsSep — join strings with separator
- lib.makeBinPath — build PATH from packages
- lib.escapeShellArg — safe shell argument escaping
- toString — convert int/path to string for interpolation
