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
    secrets = lib.mapAttrs (_: _: {}) secretMap;

    # Android specific adjustments
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
  };

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
