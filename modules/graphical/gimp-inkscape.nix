{
  config,
  pkgs,
  ...
}: let
  gimp = pkgs.gimp-with-plugins.override {
    plugins = with pkgs.gimpPlugins; [
      gmic
      resynthesizer
    ];
  };
  inkscape = pkgs.inkscape-with-extensions.override {
    inkscapeExtensions = with pkgs.inkscape-extensions; [
      applytransforms
      textext
    ];
  };
in {
  home.packages = [
    (config.dotfiles.graphical.nixgl.maybeWrap {
      package = gimp;
      bin = "gimp";
    })
    (config.dotfiles.graphical.nixgl.maybeWrap {
      package = inkscape;
      bin = "inkscape";
    })
    (config.dotfiles.graphical.nixgl.maybeWrap {
      package = pkgs.siril;
      bin = "siril";
    })
    (config.dotfiles.graphical.nixgl.maybeWrap {
      package = pkgs.stellarium;
      bin = "stellarium";
    })
  ];
}
