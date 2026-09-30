{pkgs, ...}: let
  catppucinifyRust = pkgs.callPackage ../../tools/catppucinify.nix {};
in {
  home.packages = [
    catppucinifyRust
  ];
}
