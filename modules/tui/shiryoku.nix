{
  config,
  lib,
  ...
}: {
  programs.shiryoku.enable = true;

  sops.defaultSymlinkPath = "${config.home.homeDirectory}/.local/share/sops/secrets";
  sops.defaultSecretsMountPoint = "${config.home.homeDirectory}/.local/share/sops/mount";

  sops.secrets.shiryoku_config = {};

  xdg.configFile."shiryoku/config.json".source =
    lib.mkForce (config.lib.file.mkOutOfStoreSymlink config.sops.secrets.shiryoku_config.path);
}
