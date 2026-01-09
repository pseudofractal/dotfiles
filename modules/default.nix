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

      # My packages
      inputs.mnemosyne.homeManagerModules.default
      inputs.kensaku.homeManagerModules.default
      inputs.shiryoku.homeManagerModules.default
    ]
    ++ lib.optionals (!isAndroid) [
      ./graphical
    ];
}
