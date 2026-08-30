{
  config,
  pkgs,
  ...
}: {
  home.packages = [
    (config.dotfiles.graphical.nixgl.maybeWrap {
      package = pkgs.libreoffice;
      bin = "libreoffice";
    })
  ];
}
