{
  config,
  pkgs,
  lib,
  ...
}: let
  sessionFile = "bw/session";
  cacheDir = config.xdg.cacheHome;
  sessionPath = "${cacheDir}/${sessionFile}";
  sopsClientId = config.sops.secrets.bw_client_id.path;
  sopsClientSecret = config.sops.secrets.bw_client_secret.path;
in {
  sops.secrets = {
    bw_client_id = {};
    bw_client_secret = {};
  };

  home.packages = [pkgs.bitwarden-cli];

  systemd.user.services.bw-session = {
    Unit = {
      Description = "Refresh Bitwarden session key";
      After = ["sops-nix.service" "network-online.target"];
      Wants = ["network-online.target"];
    };
    Service = {
      Type = "oneshot";
      Environment = [
        "PATH=${lib.makeBinPath [pkgs.bitwarden-cli pkgs.coreutils pkgs.bash]}"
      ];
      ExecStart = pkgs.writeShellScript "bw-refresh-session" ''
        set -euo pipefail

        BW_CLIENTID="$(cat ${sopsClientId})"
        BW_CLIENTSECRET="$(cat ${sopsClientSecret})"
        export BW_CLIENTID BW_CLIENTSECRET

        mkdir -p "$(dirname "${sessionPath}")"

        bw logout 2>/dev/null || true
        BW_SESSION="$(bw login --apikey --raw 2>/dev/null)" || true

        if [ -n "$BW_SESSION" ]; then
          echo "$BW_SESSION" > "${sessionPath}"
        fi
      '';
    };
  };

  systemd.user.timers.bw-session = {
    Unit = {
      Description = "Periodic Bitwarden session refresh";
    };
    Timer = {
      OnBootSec = "30s";
      OnUnitActiveSec = "15m";
      RandomizedDelaySec = "30s";
    };
    Install = {
      WantedBy = ["timers.target"];
    };
  };

  programs.fish.interactiveShellInit = ''
    set -l bw_session_file "${sessionPath}"
    if test -f "$bw_session_file"
      set -gx BW_SESSION (string trim < "$bw_session_file")
    end
  '';
}
