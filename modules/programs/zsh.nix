{pkgs, ...}: {
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestions.enable = true;
    syntaxHighlighting.enable = true;

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

    shellAliases = {
      # NixOS specific
      rebuild = "sudo nixos-rebuild switch --flake /home/nixos/nixos-config --impure --option builders ''";
      rebuild-test = "sudo nixos-rebuild test --flake /home/nixos/nixos-config --impure --option builders ''";
      rebuild-boot = "sudo nixos-rebuild boot --flake /home/nixos/nixos-config --impure --option builders ''";
      rebuild-dry = "nixos-rebuild build --flake /home/nixos/nixos-config --dry-run --impure --option builders ''";

      # Remote builds (on x86 Ryzen 9)
      rebuild-remote = "sudo nixos-rebuild switch --flake /home/nixos/nixos-config --impure --max-jobs 0";
      rebuild-remote-test = "sudo nixos-rebuild test --flake /home/nixos/nixos-config --impure --max-jobs 0";
      rebuild-remote-boot = "sudo nixos-rebuild boot --flake /home/nixos/nixos-config --impure --max-jobs 0";

      flake-update = "cd /home/nixos/nixos-config && nix flake update";
      flake-check = "cd /home/nixos/nixos-config && nix flake check --keep-going --impure";
      rollback = "sudo nixos-rebuild switch --rollback";

      # Cleanup, search
      nix-gc = "sudo nix-collect-garbage -d";
      nix-search = "nix search nixpkgs";

      # Better defaults
      ll = "eza -la";
      la = "eza -a";
      tree = "eza --tree";
      cat = "bat";
      c = "clear";

      # Navigation
      ".." = "cd ..";
      "..." = "cd ../..";
      "...." = "cd ../../..";

      # Common commands
      grep = "grep --color=auto";
      df = "df -h";
      du = "du -h";
      free = "free -h";
      f = "fd";
      r = "rg";
      hs = "atuin search -i";

      # System monitoring
      ports = "netstat -tuln";
      processes = "ps aux";
      mounted = "mount | column -t";

      # Git
      gs = "git status";
      glog = "git log --oneline --graph --decorate";
      gst = "git status -sb";
      ga = "git add";
      gd = "git diff";
      gco = "git checkout";
      gl = "git log --oneline --graph --decorate --all";

      # Storage
      btrfs-usage = "sudo btrfs filesystem usage /data";
      btrfs-show = "sudo btrfs filesystem show";
      btrfs-subvols = "sudo btrfs subvolume list /data";
      btrfs-scrub-status = "sudo btrfs scrub status /data";
      btrfs-balance-status = "sudo btrfs balance status /data";
      storage-info = ''
        echo "=== Disk Usage ==="
        df -h / /boot /data 2>/dev/null
        echo ""
        echo "=== BTRFS Status ==="
        sudo btrfs filesystem usage /data
        echo ""
        echo "=== Device Errors ==="
        sudo btrfs device stats /data
      '';
    };

    shellInit = ''
      # History
      HISTSIZE=10000
      SAVEHIST=10000
      setopt SHARE_HISTORY
      setopt HIST_VERIFY
      setopt HIST_IGNORE_ALL_DUPS
      setopt HIST_IGNORE_SPACE

      # Completion
      zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'

      # QoL tools
      has() {
          command -v "$1" &>/dev/null
      }

      if [[ -o interactive ]]; then
          if has fzf; then
              source <(fzf --zsh)

              if has fd; then
                  export FZF_DEFAULT_COMMAND='fd --type f --strip-cwd-prefix'
                  export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
                  export FZF_ALT_C_COMMAND='fd --type d --strip-cwd-prefix'
              fi

              export FZF_DEFAULT_OPTS='--height=40% --layout=reverse --border'
          fi

          if has zoxide; then
              eval "$(zoxide init zsh)"
          fi

          if has atuin; then
              eval "$(atuin init zsh --disable-up-arrow)"
          fi

          if has starship; then
              eval "$(starship init zsh)"
          fi
      fi

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

      # Welcome message
      if [[ -o interactive && -o login ]]; then
          echo "Welcome to NixOS on $(hostname)!"
      fi
    '';
  };

  environment.systemPackages = with pkgs; [
    eza
    bat
    fastfetch
    fd
    ripgrep
    fzf
    zoxide
    atuin
    starship
  ];
}
