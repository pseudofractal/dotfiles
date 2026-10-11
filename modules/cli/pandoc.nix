{pkgs, ...}: {
  home.packages = [
    # keep-sorted start
    pkgs.mathjax
    pkgs.pandoc
    # keep-sorted end
  ];

  home.sessionVariables.PANDOC_MATHJAX_URL = "file://${pkgs.mathjax}/lib/node_modules/mathjax/es5/tex-mml-chtml.js";

  xdg.configFile = {
    "mdview/latte.css".source = ./mdview/latte.css;
    "mdview/mocha.css".source = ./mdview/mocha.css;
  };
}
