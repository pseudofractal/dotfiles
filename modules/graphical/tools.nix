{
  pkgs,
  config,
  ...
}: {
  home.packages = [
    pkgs.iproute2
    (config.dotfiles.graphical.nixgl.maybeWrap {
      package = pkgs.mesa-demos;
      bin = "glxinfo";
    })
  ];
}
