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

  xdg.configFile = {
    "teams-for-linux/config.json".text = builtins.toJSON {
      window = {
        closeOnCross = true;
      };
    };
  };
}
