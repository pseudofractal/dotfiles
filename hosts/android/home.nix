{
  config,
  lib,
  ...
}: {
  imports = [../../modules];

  home.username = "nix-on-droid";
  home.homeDirectory = "/data/data/com.termux.nix/files/home";
  home.stateVersion = "24.05";

  xdg = {
    enable = true;
    configHome = "${config.home.homeDirectory}/.config";
    dataHome = "${config.home.homeDirectory}/.local/share";
    stateHome = "${config.home.homeDirectory}/.local/state";
    cacheHome = "${config.home.homeDirectory}/.cache";
  };

  sops.age.keyFile = "/data/data/com.termux.nix/files/home/.config/sops/age/keys.txt";

  # OPTIMIZATIONS
  # Disable man-pages generation to speed up activation
  manual.manpages.enable = false;
  manual.html.enable = false;
  manual.json.enable = false;

  # Android can't handle some Linuxisms
  services.gpg-agent.enable = lib.mkForce false;
}
