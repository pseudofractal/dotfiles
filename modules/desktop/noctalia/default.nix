{
  inputs,
  lib,
  ...
}: let
  readToml = file: builtins.readFile file;

  coreFiles = [
    ./shell.toml
    ./theme.toml
    ./wallpaper.toml
    ./bar.toml
    ./services.toml
    ./control-center.toml
  ];

  pluginFiles = [
    ./plugins/plugins.toml
    ./plugins/noctalia/timer.toml
    ./plugins/nightwatch75/file-search.toml
  ];

  allToml = lib.concatMapStringsSep "\n" readToml (coreFiles ++ pluginFiles);
in {
  imports = [
    inputs.noctalia.homeModules.default
  ];

  programs.noctalia = {
    enable = true;
    validateConfig = false;
    settings = allToml;
  };
}
