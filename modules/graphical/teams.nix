{
  config,
  pkgs,
  ...
}: {
  home.packages = [
    (config.dotfiles.graphical.nixgl.maybeWrap {
      package = pkgs.teams-for-linux;
      bin = "teams-for-linux";
    })
  ];
}
