{ config, pkgs, ... }:

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
      rebuild = "sudo nixos-rebuild switch";
      rebuild-test = "sudo nixos-rebuild test";
      rebuild-boot = "sudo nixos-rebuild boot";
      rebuild-dry = "sudo nixos-rebuild dry-build";
      rollback = "sudo nixos-rebuild switch --rollback";
      nix-search = "nix search nixpkgs";
      nix-shell = "nix-shell --run zsh";
      nixos-config = "sudo nano /etc/nixos/configuration.nix";
      nixos-hardware = "sudo nano /etc/nixos/hardware-configuration.nix";

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
      btrfs-usage = "btrfs filesystem usage /data";
      btrfs-show = "btrfs filesystem show";
      btrfs-subvols = "btrfs subvolume list /data";
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
