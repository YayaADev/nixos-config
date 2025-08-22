# modules/development/nix-tools.nix
{ config, lib, pkgs, ... }:

{
  # Install Nix development tools system-wide
  environment.systemPackages = with pkgs; [
    # Language servers for Nix
    nixd
    
    # Formatters
    nixfmt-rfc-style
    
    # Additional Nix tools
    nixpkgs-review    # Review nixpkgs PRs
    nix-tree          # Visualize dependency trees
    statix            # Linter for Nix
    deadnix           # Remove unused Nix code
    
    # Development helpers
    nix-init          # Generate Nix expressions from URLs
    nix-update        # Update Nix expressions
  ];

  # Enable nix-ld for better VS Code compatibility
  programs.nix-ld = {
    enable = true;
    libraries = with pkgs; [
      # Add any additional libraries VS Code extensions might need
      stdenv.cc.cc.lib
      nodejs_18
    ];
  };
}