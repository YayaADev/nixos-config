# Verify Before Writing Nix

You hallucinate NixOS options. This is the #1 source of broken configs. Follow this protocol for every option you write.

## Before using ANY services.*, programs.*, networking.*, systemd.*, or virtualisation.* option:

1. **If you are not 100% certain the option exists with that exact name and type** — verify it:
   - Run: nix eval --impure --expr 'let flake = builtins.getFlake "/home/nixos/nixos-config"; in flake.nixosConfigurations.nixos-cm3588.options.services.FOO' 2>&1 | head -5
   - Or WebFetch from search.nixos.org/options with the option name
   - Or grep nixpkgs source to find the module that declares the option

2. **If you cannot verify an option exists, say so.** Do not write it and hope.

3. **Common hallucinations to watch for:**
   - Inventing sub-options that don't exist (e.g., writing services.foo.settings.bar when only services.foo.extraConfig exists)
   - Wrong types: passing a string where a list is expected, or vice versa
   - Using old option names that were renamed or removed in recent nixpkgs
   - Confusing Home Manager options with NixOS system options
   - Options from services.foo that actually live under programs.foo or vice versa
   - Guessing systemd.services option structure: serviceConfig keys are systemd directive names (ExecStart, User, Restart), not Nix-invented names

4. **For packages**: verify with nix search nixpkgs#NAME before adding to environment.systemPackages

## When writing a NEW module:

- Look at an existing module in this repo first (modules/services/*.nix) for the pattern
- For native services: check nixpkgs source to understand available options. Most services expose enable, package, settings, and sometimes extraConfig
- For containers: follow the template in CLAUDE.md, reference modules/services/pods/ for the established pattern

## The config argument and mkIf:

- NEVER use bare "if config.foo then {...} else {}" — this causes infinite recursion during module evaluation
- ALWAYS use lib.mkIf for conditional config blocks
- Access the module's own config via: let cfg = config.services.foo; in ...

## Nix language gotchas to never forget:

- Lists use whitespace separators, not commas: [ "a" "b" "c" ]
- [ f x ] is a two-element list, not a function call. Use [ (f x) ] for application.
- String interpolation only works on strings — "${42}" is a type error. Use toString.
- Attribute sets are NOT recursive by default. Use rec { } or let bindings for self-references.
- Paths in interpolation copy to the nix store. Use toString to avoid this when referencing mutable paths.
- The // operator is shallow merge (one level). It does NOT deep-merge nested attrsets.
