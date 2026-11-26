{
  config,
  lib,
  pkgs,
  ...
}: let
  catppuccinPalette = pkgs.fetchzip {
    url = "https://github.com/catppuccin/palette/releases/download/v1.8.0/catppuccin.tar.gz";
    hash = "sha256-CN+syYnkCDWkq0DqYqeDwV0G33LggHW7xooHrvKkf9A=";
    stripRoot = false;
  };
  scientificInkscape = pkgs.fetchzip {
    url = "https://github.com/burghoff/Scientific-Inkscape/archive/refs/tags/v1.4.26.tar.gz";
    hash = "sha256-8QqyW4Yqb8Z9Sw1sJRn4Aamha/j7s7XLdUOySO4lypk=";
  };
  circuitikzSymbols = pkgs.fetchzip {
    url = "https://github.com/medwatt/circuitikz_symbols/archive/30a391112598e5734495f7d96f7b5a2d90d2cdb1.tar.gz";
    hash = "sha256-raitd/atHImLhqc24r3DLaubLoUx7vaYh3imNALJ7k8=";
  };
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
  home.activation.installScientificInkscape = lib.hm.dag.entryAfter ["writeBoundary"] ''
    extension_dir="${config.xdg.configHome}/inkscape/extensions"
    $DRY_RUN_CMD install -d "$extension_dir"
    $DRY_RUN_CMD cp -R "${scientificInkscape}/scientific_inkscape/." "$extension_dir/"
    # Favorite Markers stores preferences beside its script; keep this user copy writable.
    $DRY_RUN_CMD chmod -R u+rwX "$extension_dir"
  '';

  home.activation.setInkscapeDefaults = lib.hm.dag.entryAfter ["linkGeneration" "installScientificInkscape"] ''
    if pgrep -x inkscape >/dev/null 2>&1; then
      echo "warning: Inkscape is running; close it and rebuild to apply the configured defaults" >&2
    else
      $DRY_RUN_CMD ${pkgs.python3}/bin/python3 ${./inkscape-defaults.py} "${config.xdg.configHome}/inkscape/preferences.xml"
    fi
  '';

  xdg.configFile =
    lib.listToAttrs (map (flavor: {
        name = "inkscape/palettes/Catppuccin ${flavor}.gpl";
        value.source = "${catppuccinPalette}/gimp/Catppuccin ${flavor}.gpl";
      })
      ["Frappe" "Latte" "Macchiato" "Mocha"])
    // {
      "inkscape/symbols/CircuiTikZ - Common.svg".source = "${circuitikzSymbols}/circuitikz_common.svg";
      "inkscape/symbols/CircuiTikZ - All.svg".source = "${circuitikzSymbols}/circuitikz_all.svg";
      "inkscape/extensions/label_parts.py".source = "${circuitikzSymbols}/extension/label_parts.py";
      "inkscape/extensions/label_parts.inx".source = "${circuitikzSymbols}/extension/label_parts.inx";
      "inkscape/templates/Scientific Illustration - Square.svg".source = ./inkscape-templates/scientific-illustration-square.svg;
      "inkscape/templates/Scientific Illustration - Rectangle.svg".source = ./inkscape-templates/scientific-illustration-rectangle.svg;
      "inkscape/palettes/Catppuccin Mocha Scientific.gpl".source = ./inkscape-palettes/catppuccin-mocha-scientific.gpl;
    };

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
