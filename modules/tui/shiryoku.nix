{
  config,
  lib,
  ...
}: {
  programs.shiryoku.enable = true;

  sops.secrets.shiryoku_config = {};

  # [NOTE]
  # 'lib.mkForce' overwrites the logic inside the flake.nix that generates the public config
  # 'mkOutOfStoreSymlink' creates a link to the runtime secret path
  xdg.configFile."shiryoku/config.json".source =
    lib.mkForce (config.lib.file.mkOutOfStoreSymlink config.sops.secrets.shiryoku_config.path);
}
