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
  services.gnome-keyring = {
    enable = true;
    components = ["secrets"];
  };

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
  };

  home.activation.opencodeGoApiKey = lib.mkIf (!isAndroid) (lib.hm.dag.entryAfter ["sops-nix"] ''
    auth_file="${config.home.homeDirectory}/.local/share/opencode/auth.json"
    key_file=${lib.escapeShellArg config.sops.templates."opencode-go-api-key".path}
    if [ -r "$key_file" ]; then
      $DRY_RUN_CMD ${pkgs.coreutils}/bin/mkdir -p "$(${pkgs.coreutils}/bin/dirname "$auth_file")"
      if [ -f "$auth_file" ]; then
        if $DRY_RUN_CMD ${pkgs.jq}/bin/jq --rawfile key "$key_file" \
          '.["opencode-go"] = ((.["opencode-go"] // {}) + {type: "api", key: ($key | rtrimstr("\n"))})' \
          "$auth_file" > "$auth_file.tmp"; then
          $DRY_RUN_CMD ${pkgs.coreutils}/bin/chmod 600 "$auth_file.tmp"
          $DRY_RUN_CMD ${pkgs.coreutils}/bin/mv "$auth_file.tmp" "$auth_file"
        else
          ${pkgs.coreutils}/bin/rm -f "$auth_file.tmp"
        fi
      else
        if $DRY_RUN_CMD ${pkgs.jq}/bin/jq -n --rawfile key "$key_file" \
          '{["opencode-go"]: {type: "api", key: ($key | rtrimstr("\n"))}}' > "$auth_file.tmp"; then
          $DRY_RUN_CMD ${pkgs.coreutils}/bin/chmod 600 "$auth_file.tmp"
          $DRY_RUN_CMD ${pkgs.coreutils}/bin/mv "$auth_file.tmp" "$auth_file"
        else
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
