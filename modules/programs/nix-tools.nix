{
  lib,
  pkgs,
  ...
}: {
  # Install Nix development tools system-wide
  environment.systemPackages = with pkgs; [
    # Language servers
    nixd

    # Formatters & linters
    alejandra
    statix
    deadnix

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

  # Make Alejandra the default formatter for nix-ide
  environment.variables.NIX_FORMATTER = "alejandra";
}
