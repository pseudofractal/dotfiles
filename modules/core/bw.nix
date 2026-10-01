{
  config,
  pkgs,
  ...
}: {
  # rbw manages its own background agent (like ssh-agent): commands
  # auto-login/unlock as needed, so no refresh timer is required.
  programs.rbw.enable = true;

  # Kept as a manual fallback; day-to-day vault access is via rbw.
  home.packages = [pkgs.bitwarden-cli];

  # Email stays encrypted in the repo; everything else is rbw's default
  # (bitwarden.com, pinentry) with a 24h agent unlock cache.
  sops.secrets.rbw_email = {};

  sops.templates."rbw-config.json" = {
    path = "${config.xdg.configHome}/rbw/config.json";
    mode = "0600";
    content = builtins.toJSON {
      email = config.sops.placeholder.rbw_email;
      lock_timeout = 86400;
      pinentry = "${pkgs.pinentry-tty}/bin/pinentry";
    };
  };
}
