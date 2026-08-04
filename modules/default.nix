{
  inputs,
  lib,
  isAndroid,
  ...
}: {
  imports =
    [
      # keep-sorted start
      ./cli
      ./core
      ./programming
      ./tui
      # keep-sorted end

      # External Modules from Flake Inputs
      inputs.sops-nix.homeManagerModules.sops
      inputs.catppuccin.homeModules.catppuccin

      # My packages
    ]
    ++ lib.optionals (!isAndroid) [
      inputs.vicinae.homeManagerModules.default
      ./cli/vicinae.nix
      ./graphical
      ./desktop
    ];
}
