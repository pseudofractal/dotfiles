{
  config,
  lib,
  pkgs,
  isAndroid,
  ...
}: let
  secretMap = {
    github_token = "GITHUB_PERSONAL_ACCESS_TOKEN";
    figma_key = "FIGMA_API_KEY";
    mercury_token = "MERCURY_AI_TOKEN";
    wifi_password = "WIFI_PASSWORD";
    annas_archive_token_password = "ANNAS_ARCHIVE_TOKEN";
    opencode_go_api_key = "OPENCODE_API_KEY";
  };

  sopsService = config.systemd.user.services.sops-nix;
  sopsCommand = lib.escapeShellArgs (lib.toList sopsService.Service.ExecStart);
in {
  sops = {
    defaultSopsFile = ../../secrets.yaml;
    defaultSopsFormat = "yaml";
    age.keyFile = "${config.xdg.configHome}/sops/age/keys.txt";
    secrets =
      (lib.mapAttrs (_: _: {}) secretMap)
      // {
        "mail/app-passwords/google/iiser" = {};
        "mail/app-passwords/google/personal" = {};
      };

    defaultSymlinkPath = lib.mkIf isAndroid "${config.xdg.dataHome}/sops/secrets";
    defaultSecretsMountPoint = lib.mkIf isAndroid "${config.xdg.dataHome}/sops/mount";

    templates."exported-vars.fish" = {
      content = lib.concatStringsSep "\n" (
        lib.mapAttrsToList (secretName: envVar: ''
          set -gx ${envVar} "${config.sops.placeholder.${secretName}}"
        '')
        secretMap
      );
    };

    templates."opencode-go-api-key".content = config.sops.placeholder.opencode_go_api_key;

    # Nix resolves flake inputs through api.github.com; include the token from a
    # 0400 file so all Nix invocations (interactive and non-interactive) avoid
    # the 60/hour anonymous limit without leaking the token via NIX_CONFIG.
    templates."nix-access-tokens.conf" = {
      mode = "0400";
      content = ''
        access-tokens = github.com=${config.sops.placeholder.github_token}
      '';
    };
  };

  nix.extraOptions = "!include ${config.sops.templates."nix-access-tokens.conf".path}";

  home.activation.opencodeGoApiKey = lib.mkIf (!isAndroid) (lib.hm.dag.entryAfter ["sops-nix"] ''
    auth_file="${config.home.homeDirectory}/.local/share/opencode/auth.json"
    key_file=${lib.escapeShellArg config.sops.templates."opencode-go-api-key".path}
    if [ -r "$key_file" ]; then
      if [[ -v DRY_RUN ]]; then
        echo "Dry run: would update $auth_file from $key_file"
      else
        ${pkgs.coreutils}/bin/mkdir -p "$(${pkgs.coreutils}/bin/dirname "$auth_file")"
        jq_filter='.["opencode-go"] = ((.["opencode-go"] // {}) + {type: "api", key: ($key | rtrimstr("\n"))})'
        if (
          umask 077
          if [ -f "$auth_file" ]; then
            ${pkgs.jq}/bin/jq --rawfile key "$key_file" "$jq_filter" "$auth_file" > "$auth_file.tmp"
          else
            ${pkgs.jq}/bin/jq -n --rawfile key "$key_file" "$jq_filter" > "$auth_file.tmp"
          fi
        ); then
          ${pkgs.coreutils}/bin/chmod 600 "$auth_file.tmp"
          ${pkgs.coreutils}/bin/mv "$auth_file.tmp" "$auth_file"
        else
          echo "warning: failed to update $auth_file" >&2
          ${pkgs.coreutils}/bin/rm -f "$auth_file.tmp"
        fi
      fi
    fi
  '');

  programs.fish.interactiveShellInit = ''
    if test -f ${config.sops.templates."exported-vars.fish".path}
      source ${config.sops.templates."exported-vars.fish".path}
    end
  '';

  home.activation.sopsNixForce = lib.mkIf isAndroid (lib.hm.dag.entryAfter ["writeBoundary"] ''
    echo "🔐 Decrypting secrets via sops-nix..."
    export XDG_RUNTIME_DIR="${config.xdg.cacheHome}/sops-nix"
    mkdir -p "$XDG_RUNTIME_DIR"
    $DRY_RUN_CMD ${pkgs.bash}/bin/bash -c ${lib.escapeShellArg sopsCommand}
  '');
}
