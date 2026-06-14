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

  fixedVivaldi = pkgs.symlinkJoin {
    name = "vivaldi-fixed";
    paths = [pkgs.vivaldi];

    nativeBuildInputs = [pkgs.makeWrapper];

    postBuild = ''
      wrapProgram $out/bin/vivaldi \
        --prefix LD_LIBRARY_PATH : $out/opt/vivaldi
    '';
  };
in {
  home.packages = [
    (nixgl.maybeWrap {
      package = fixedVivaldi;
      bin = "vivaldi";
    })
  ];
}
