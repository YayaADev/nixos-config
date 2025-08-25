{
  lib,
  pkgs,
  ...
}: {
  # === VS CODE REMOTE SSH SUPPORT ===
  programs.nix-ld = {
    enable = true;
    libraries = with pkgs; [
      stdenv.cc.cc.lib
      curl
      openssl
      gitMinimal
      nodejs_18
      python3
      zlib
      krb5
      libsecret
    ];
  };

  # Auto-fix systemd service for VS Code Server
  systemd.user.services.auto-fix-vscode-server = {
    description = "Automatically fix VS Code server";
    serviceConfig = {
      ExecStart = "${pkgs.writeShellScript "auto-fix-vscode-server" ''
        set -euo pipefail
        PATH=${lib.makeBinPath (with pkgs; [coreutils inotify-tools findutils])}

        nodePath="${pkgs.nodejs_18}/bin/node"
        bin_dir="$HOME/.vscode-server/bin"

        [[ -e "$bin_dir" ]] && \
        find "$bin_dir" -mindepth 2 -maxdepth 2 -name node -type f -exec ln -sfT "$nodePath" {} \; || \
        mkdir -p "$bin_dir"

        while IFS=: read -r bin_dir event; do
          if [[ $event == 'CREATE,ISDIR' ]]; then
            touch "$bin_dir/node"
            inotifywait -qq -e DELETE_SELF "$bin_dir/node"
            ln -sfT "$nodePath" "$bin_dir/node"
          elif [[ $event == DELETE_SELF ]]; then
            exit 0
          fi
        done < <(inotifywait -q -m -e CREATE,ISDIR -e DELETE_SELF --format '%w%f:%e' "$bin_dir")
      ''}";
      Restart = "always";
      RestartSec = "0";
    };
    wantedBy = ["default.target"];
  };
}
