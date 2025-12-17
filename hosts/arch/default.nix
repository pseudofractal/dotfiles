{
  config,
  pkgs,
  ...
}: {
  imports = [
    ../../modules/core/default.nix
  ];

  home.username = "pseudofractal";
  home.homeDirectory = "/home/pseudofractal/";

  home.stateVersion = "26.05";
  programs.home-manager.enable = true;
}
