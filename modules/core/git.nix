{pkgs, ...}: {
  programs.git = {
    enable = true;
    lfs = {
      enable = true;
      skipSmudge = true;
    };
    settings = {
      user = {
        name = "PseudoFractal";
        email = "kshitishkumarratha@gmail.com";
      };
      github.user = "pseudofractal";
      init.defaultBranch = "main";

      color.ui = "auto";
      core.editor = "nvim";
    };
  };
  programs.gh = {
    enable = true;
    gitCredentialHelper = {
      enable = true;
    };
  };
}
