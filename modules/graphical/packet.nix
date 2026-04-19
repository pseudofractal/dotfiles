{
  pkgs,
  lib,
  config,
  inputs,
  isNixOS,
  ...
}: let
  nixgl = import ./nixgl-helper.nix {
    inherit config lib pkgs inputs isNixOS;
  };
in {
  home.packages = [
    (nixgl.maybeWrap {
      package = pkgs.packet;
      bin = "packet";
    })
  ];
}
