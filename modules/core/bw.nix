{
  config,
  pkgs,
  ...
}: {
  programs.rbw.enable = true;

  home.packages = [pkgs.bitwarden-cli];

  sops.secrets.rbw_email = {};

  sops.templates."rbw-config.json" = {
    path = "${config.xdg.configHome}/rbw/config.json";
    mode = "0600";
    content = builtins.toJSON {
      email = config.sops.placeholder.rbw_email;
      lock_timeout = 24 * 60 * 60;
      pinentry = "${pkgs.pinentry-tty}/bin/pinentry";
    };
  };
}
