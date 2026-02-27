{inputs, ...}: {
  imports = [../../modules];
  nixpkgs.config.allowUnfree = true;

  home.username = "pseudofractal";
  home.homeDirectory = "/home/pseudofractal";

  home.stateVersion = "24.11";

  home.packages = [
  ];

  xdg = {
    enable = true;
    userDirs.enable = true;
    userDirs.createDirectories = true;
  };

  programs.home-manager.enable = true;
}
