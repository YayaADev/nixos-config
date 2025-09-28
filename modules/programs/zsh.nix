{ pkgs, ... }:
{
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestions.enable = true;
    syntaxHighlighting.enable = true;

    # ohMyZsh
    ohMyZsh = {
      enable = true;
      theme = "robbyrussell";
      plugins = [
        "git"
        "sudo"
        "command-not-found"
        "history"
        "colored-man-pages"
      ];
    };

    # shellAliases
    shellAliases = {
      # NixOS specific
      rebuild = "sudo nixos-rebuild switch --flake /home/nixos/nixos-config --impure";
      rebuild-test = "sudo nixos-rebuild test --flake /home/nixos/nixos-config --impure";
      rebuild-boot = "sudo nixos-rebuild boot --flake /home/nixos/nixos-config --impure";
      rebuild-dry = "nixos-rebuild build --flake /home/nixos/nixos-config --dry-run --impure";

      flake-update = "cd /home/nixos/nixos-config && nix flake update";
      flake-check = "cd /home/nixos/nixos-config && nix flake check --keep-going --impure";
      rollback = "sudo nixos-rebuild switch --rollback";

      # Cleanup, search
      nix-gc = "sudo nix-collect-garbage -d";
      nix-search = "nix search nixpkgs";

      ll = "eza -la";
      la = "eza -a";
      tree = "eza --tree";
      cat = "bat";

      # Navigation
      ".." = "cd ..";
      "..." = "cd ../..";
      "...." = "cd ../../..";

      # Common commands
      grep = "grep --color=auto";
      df = "df -h";
      du = "du -h";
      free = "free -h";

      # System monitoring
      ports = "netstat -tuln";
      processes = "ps aux";
      mounted = "mount | column -t";

      # Git
      gst = "git status";
      glog = "git log --oneline --graph --decorate";

      # Storage
      btrfs-usage = "sudo btrfs filesystem usage /data";
      btrfs-show = "sudo btrfs filesystem show";
      btrfs-subvols = "sudo btrfs subvolume list /data";
      btrfs-scrub-status = "btrfs scrub status /data";
      btrfs-balance-status = "btrfs balance status /data";
      storage-info = "df -h /data && echo && btrfs filesystem usage /data";
    };

    # shellInit
    shellInit = ''
      # History
      HISTSIZE=10000
      SAVEHIST=10000
      setopt SHARE_HISTORY
      setopt HIST_VERIFY
      setopt HIST_IGNORE_ALL_DUPS
      setopt HIST_IGNORE_SPACE

      # Completion
      autoload -Uz compinit
      compinit
      zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'

      # Functions
      sysinfo() {
          echo "=== System Information ==="
          echo "Hostname: $(hostname)"
          if uptime -p &>/dev/null; then
              echo "Uptime: $(uptime -p)"
          else
              echo "Uptime: $(uptime | awk -F, '{print $1}' | awk '{print $3,$4}')"
          fi
          echo "Load: $(uptime | awk -F'load average:' '{print $2}')"
          echo "Memory: $(free -h | awk '/^Mem:/ {print $3 "/" $2}')"
          echo "Disk: $(df -h / | awk 'NR==2 {print $3 "/" $2 " (" $5 " used)"}')"
          echo "NixOS: $(nixos-version)"
      }

      cd() {
          builtin cd "$@"
          if command -v eza &> /dev/null; then
              eza -la
          else
              ls -la
          fi
      }

      # Welcome message
      if [[ -o interactive ]]; then
          echo "Welcome to NixOS on $(hostname)!"
          if command -v neofetch &> /dev/null; then
              neofetch
          else
              sysinfo
          fi
      fi
    '';
  };

  environment.systemPackages = with pkgs; [
    zsh
    oh-my-zsh
    eza
    bat
    neofetch
  ];
}
