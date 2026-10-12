{
  inputs,
  lib,
  isAndroid,
  ...
}: let
  localModules = [
    # keep-sorted start
    ./cli
    ./core
    ./programming
    ./tui
    # keep-sorted end
  ];

  flakeModules = [
    inputs.catppuccin.homeModules.catppuccin
    inputs.sops-nix.homeManagerModules.sops
  ];

  desktopModules = lib.optionals (!isAndroid) [
    inputs.vicinae.homeManagerModules.default
    ./cli/vicinae.nix
    ./graphical
    ./desktop
  ];
in {
  imports = localModules ++ flakeModules ++ desktopModules;
}
