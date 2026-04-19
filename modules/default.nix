{
  inputs,
  lib,
  isAndroid,
  ...
}: {
  imports =
    [
      ./core
      ./cli
      ./tui
      ./programming

      # External Modules from Flake Inputs
      inputs.sops-nix.homeManagerModules.sops
      inputs.catppuccin.homeModules.catppuccin
      inputs.nvf.homeManagerModules.default

      # My packages
    ]
    ++ lib.optionals (!isAndroid) [
      ./graphical
    ];
}
