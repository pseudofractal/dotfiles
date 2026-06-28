{
  pkgs,
  lib,
  config,
  ...
}: let
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
    (config.dotfiles.graphical.nixgl.maybeWrap {
      package = fixedVivaldi;
      bin = "vivaldi";
    })
  ];
}
