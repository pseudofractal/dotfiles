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
      inputs.lmstudio.homeManagerModules.default
      inputs.nvf.homeManagerModules.default

      # My packages
    ]
    ++ lib.optionals (!isAndroid) [
      ./graphical
    ];
}
