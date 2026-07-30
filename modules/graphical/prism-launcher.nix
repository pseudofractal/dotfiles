{
  config,
  pkgs,
  ...
}: let
  dataDir = "${config.xdg.dataHome}/PrismLauncher";
  themeName = "Catppuccin Mocha";
  themeDir = "${dataDir}/themes/${themeName}";

  jsonFormat = pkgs.formats.json {};

  themeJson = jsonFormat.generate "prismlauncher-catppuccin-mocha-theme.json" {
    name = themeName;
    widgets = "Fusion";

    colors = {
      AlternateBase = "#1e1e2e";
      Base = "#181825";
      BrightText = "#bac2de";
      Button = "#313244";
      ButtonText = "#cdd6f4";
      Highlight = "#94e2d5";
      HighlightedText = "#1e1e2e";
      Link = "#94e2d5";
      Text = "#cdd6f4";
      ToolTipBase = "#dee5fc";
      ToolTipText = "#dee5fc";
      Window = "#1e1e2e";
      WindowText = "#bac2de";
      fadeAmount = 0.5;
      fadeColor = "#6c7086";
    };

    logColors = {
      Debug = "#a6e3a1";
      Error = "#f38ba8";
      Fatal = "#181825";
      FatalHighlight = "#f38ba8";
      Launcher = "#cba6f7";
      Warning = "#f9e2af";
    };
  };

  themeCss = pkgs.writeText "prismlauncher-catppuccin-mocha-theme.css" ''
    QToolTip {
      color: #cdd6f4;
      background-color: #313244;
      border: 1px solid #313244;
    }
  '';

  prismlauncher = config.dotfiles.graphical.nixgl.maybeWrap {
    package = pkgs.prismlauncher;
    bin = "prismlauncher";
  };
in {
  programs.prismlauncher = {
    enable = true;
    package = prismlauncher;

    settings = {
      ApplicationTheme = themeName;
      InstSortMode = "Name";
      MaxMemAlloc = 4096;
      MinMemAlloc = 2048;
      ShowConsole = true;
    };
  };

  xdg.dataFile."${themeDir}/resources/.keep".text = "";
  xdg.dataFile."${themeDir}/theme.json".source = themeJson;
  xdg.dataFile."${themeDir}/themeStyle.css".source = themeCss;
}
