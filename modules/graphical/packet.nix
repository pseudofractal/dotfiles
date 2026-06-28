{
  pkgs,
  lib,
  config,
  ...
}: {
  home.packages = [
    (config.dotfiles.graphical.nixgl.maybeWrap {
      package = pkgs.packet;
      bin = "packet";
    })
  ];
}
