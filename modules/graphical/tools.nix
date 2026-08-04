{
  pkgs,
  config,
  ...
}: {
  home.packages = [
    pkgs.iproute2
    pkgs.kdePackages.audiotube
    (config.dotfiles.graphical.nixgl.maybeWrap {
      package = pkgs.mesa-demos;
      bin = "glxinfo";
    })
  ];
}
