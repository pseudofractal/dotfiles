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
    wifi_password = "WIFI_PASSWORD";
  };
in {
  sops = {
    defaultSopsFile = ../../secrets.yaml;
    defaultSopsFormat = "yaml";

    age.keyFile = "${config.xdg.configHome}/sops/age/keys.txt";

    secrets = lib.mapAttrs (_: _: {}) secretMap;

    # Android Specifics
    # Cannot use /run/user/1000 on Android (no tmpfs/permissions).
    defaultSymlinkPath =
      lib.mkIf isAndroid
      "${config.xdg.dataHome}/sops/secrets";

    defaultSecretsMountPoint =
      lib.mkIf isAndroid
      "${config.xdg.dataHome}/sops/mount";

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

  # Systemd hack to force manual sops-nix decryption on Android
  home.activation.sopsNixForce = lib.mkIf isAndroid (lib.hm.dag.entryAfter ["writeBoundary"] ''
    echo "Android Detected: Forcing manual sops-nix decryption."
    $DRY_RUN_CMD ${pkgs.bash}/bin/bash -c "${config.systemd.user.services.sops-nix.Service.ExecStart}"
  '');
}
