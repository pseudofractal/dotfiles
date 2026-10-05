{
  config,
  pkgs,
  ...
}: {
  home.packages = [
    (config.dotfiles.graphical.nixgl.maybeWrap {
      package = pkgs.google-chrome;
      bin = "google-chrome-stable";
    })
  ];
}
