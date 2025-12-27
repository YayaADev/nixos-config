{ pkgs, ... }:
{
  # Install Nix development tools system-wide
  environment.systemPackages = with pkgs; [
    nixd

    # Formatters & linters
    nixfmt-rfc-style 
    statix # 
    deadnix 

    # Nix utilities
    nixpkgs-review
    nix-tree
    nix-init
    nix-update
  ];

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
