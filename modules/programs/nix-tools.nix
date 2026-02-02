{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    nixd
    nixfmt
  ];

  programs = {
    git.enable = true;
    zsh.enable = true;
  };

  # Use nixfmt as the default formatter for Nix IDEs
  environment.variables.NIX_FORMATTER = "nixfmt";
}
