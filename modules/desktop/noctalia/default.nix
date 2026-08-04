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
    ./plugins/DotNetRob/cat.toml
    ./plugins/noctalia/timer.toml
    ./plugins/plugins.toml
  ];

  allToml = lib.concatMapStringsSep "\n" readToml (coreFiles ++ pluginFiles);
in {
  imports = [
    ./lrc_tty.nix
    inputs.noctalia.homeModules.default
  ];

  programs.noctalia = {
    enable = true;
    validateConfig = false;
    settings = allToml;
  };
}
