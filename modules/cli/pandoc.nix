{pkgs, ...}: {
  home.packages = [
    pkgs.mathjax
    pkgs.pandoc
  ];

  home.sessionVariables.PANDOC_MATHJAX_URL = "file://${pkgs.mathjax}/lib/node_modules/mathjax/es5/tex-mml-chtml.js";

  xdg.configFile = {
    "mdview/latte.css".source = ./mdview/latte.css;
    "mdview/mocha.css".source = ./mdview/mocha.css;
  };
}
