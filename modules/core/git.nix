{config, ...}: {
  programs.git = {
    enable = true;
    signing.format = "openpgp";
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
      core.excludesFile = "${config.xdg.configHome}/git/ignore";
    };
  };
  xdg.configFile."git/ignore".text = ''
    .julia-depot/
  '';
  programs.gh = {
    enable = true;
    gitCredentialHelper = {
      enable = true;
    };
  };
}
