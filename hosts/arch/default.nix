{inputs, ...}: {
  imports = [../../modules];
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
    package = "nixGLIntel";
  };

  programs.home-manager.enable = true;

  dotfiles.backup = {
    enable = true;
    baseFolder = "backups";
    entries = {
      documents = {
        sourcePath = "~/Documents";
        drivePath = "documents";
        incremental = true;
        schedule = "*-*-* 11:00:00";
      };
    };
  };
}
