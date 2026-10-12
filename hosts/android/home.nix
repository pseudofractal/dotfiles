{
  config,
  lib,
  inputs,
  system,
  ...
}: {
  imports = [../../modules];

  home.username = "nix-on-droid";
  home.homeDirectory = "/data/data/com.termux.nix/files/home";
  home.stateVersion = "24.05";
  news.display = "silent";

  xdg = {
    enable = true;
    configHome = "${config.home.homeDirectory}/.config";
    dataHome = "${config.home.homeDirectory}/.local/share";
    stateHome = "${config.home.homeDirectory}/.local/state";
    cacheHome = "${config.home.homeDirectory}/.cache";
  };

  sops.age.keyFile = "${config.home.homeDirectory}/.config/sops/age/keys.txt";

  manual.manpages.enable = false;
  manual.html.enable = false;
  manual.json.enable = false;

  services.gpg-agent.enable = lib.mkForce false;
}
