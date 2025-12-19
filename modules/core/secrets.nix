{
  config,
  ...
}: {
  sops = {
    # Assume your keys.txt is at ~/.config/sops/age/keys.txt
    defaultSopsFile = ../../secrets.yaml;
    defaultSopsFormat = "yaml";

    age.keyFile = "${config.xdg.configHome}/sops/age/keys.txt";

    # Secrets
    secrets.github_token = {};
    secrets.figma_key = {};
  };

  # sops-nix stores secrets in $XDG_RUNTIME_DIR/secrets/ by default
  programs.fish.interactiveShellInit = ''
    if test -f ${config.sops.secrets.github_token.path}
        set -gx GITHUB_PERSONAL_ACCESS_TOKEN (cat ${config.sops.secrets.github_token.path})
    end

    if test -f ${config.sops.secrets.figma_key.path}
        set -gx FIGMA_API_KEY (cat ${config.sops.secrets.figma_key.path})
    end
  '';
}
