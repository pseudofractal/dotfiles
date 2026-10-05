{
  config,
  pkgs,
  ...
}: {
  home.packages = [
    (config.dotfiles.graphical.nixgl.maybeWrap {
      package = pkgs.freecad;
      bin = "freecad";
    })
    (config.dotfiles.graphical.nixgl.maybeWrap {
      package = pkgs.openscad-unstable;
      bin = "openscad";
    })
    (config.dotfiles.graphical.nixgl.maybeWrap {
      package = pkgs.solvespace;
      bin = "solvespace";
    })
  ];
}
