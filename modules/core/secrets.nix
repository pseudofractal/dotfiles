{
  config,
  lib,
  pkgs,
  hostName ? "",
  ...
}: let
  isKoch = hostName == "koch";

  secretEnvVars = {
    github_token = "GITHUB_PERSONAL_ACCESS_TOKEN";
    figma_key = "FIGMA_API_KEY";
  };
in {
  sops = {
    defaultSopsFile = ../../secrets.yaml;
    defaultSopsFormat = "yaml";
    age.keyFile = "${config.xdg.configHome}/sops/age/keys.txt";

    secrets = lib.mapAttrs (name: _: {}) secretEnvVars;

    defaultSymlinkPath =
      lib.mkIf isKoch
      "${config.home.homeDirectory}/.local/share/sops/secrets";
    defaultSecretsMountPoint =
      lib.mkIf isKoch
      "${config.home.homeDirectory}/.local/share/sops/mount";

    templates."exported-vars.fish" = {
      content = lib.concatStringsSep "\n" (
        lib.mapAttrsToList (secretName: envVar: ''
          set -gx ${envVar} "${config.sops.placeholder.${secretName}}"
        '')
        secretEnvVars
      );
    };
  };

  programs.fish.interactiveShellInit = ''
    if test -f ${config.sops.templates."exported-vars.fish".path}
      source ${config.sops.templates."exported-vars.fish".path}
    end
  '';

  home.activation.sopsNixForce = lib.mkIf isKoch (lib.hm.dag.entryAfter ["writeBoundary"] ''
    echo "Host is Koch: Forcing manual sops-nix decryption..."
    $DRY_RUN_CMD ${pkgs.bash}/bin/bash -c "${config.systemd.user.services.sops-nix.Service.ExecStart}"
  '');
}
