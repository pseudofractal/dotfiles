{inputs, ...}: {
  imports = [../../modules];
  nixpkgs.config.allowUnfree = true;

  home.username = "pseudofractal";
  home.homeDirectory = "/home/pseudofractal";

  home.stateVersion = "24.11";
  news.display = "silent";

  home.packages = [
  ];

  xdg = {
    enable = true;
    userDirs.enable = true;
    userDirs.createDirectories = true;
    userDirs.setSessionVariables = true;
  };

  dotfiles.graphical.nixgl = {
    enable = true;
    package = "nixGLDefault";
  };

  programs.home-manager.enable = true;
}
