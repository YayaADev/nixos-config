# modules/programs/nix-tools.nix
{ lib, pkgs, ... }:
{
  # Install Nix development tools system-wide
  environment.systemPackages = with pkgs; [
    # Language server
    nixd

    # Formatters & linters (up-to-date standard)
    nixfmt-rfc-style # official RFC-style formatter
    statix # linter
    deadnix # dead code detector

    # Nix utilities
    nixpkgs-review
    nix-tree
    nix-init
    nix-update
  ];

  # Recommended shell & dev tools
  programs = {
    nix-ld = {
      enable = true;
      libraries = with pkgs; [
        stdenv.cc.cc.lib
        nodejs_20
      ];
    };

    git.enable = true;
    zsh.enable = true;
  };

  # Use nixfmt as the default formatter for Nix IDEs
  environment.variables.NIX_FORMATTER = "nixfmt";
}
