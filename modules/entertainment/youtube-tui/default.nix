{
  lib,
  pkgs,
  ...
}: let
  configFiles = [
    "appearance.yml"
    "cmdefine.yml"
    "commandbindings.yml"
    "commands.yml"
    "keybindings.yml"
    "main.yml"
    "pages.yml"
    "remaps.yml"
  ];
in {
  home.packages = with pkgs; [
    youtube-tui
  ];

  xdg.configFile = lib.listToAttrs (map (name: {
      name = "youtube-tui/${name}";
      value.source = ./. + "/${name}";
    })
    configFiles);
}
