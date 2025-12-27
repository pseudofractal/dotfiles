{
  config,
  lib,
  ...
}: {
  programs.shiryoku.enable = true;

  sops.secrets.shiryoku_config = {};
  xdg.configFile."shiryoku/config.json".source =
    lib.mkForce (config.lib.file.mkOutOfStoreSymlink config.sops.secrets.shiryoku_config.path);
}
