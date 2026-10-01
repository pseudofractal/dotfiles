{
  config,
  lib,
  pkgs,
  ...
}: let
  themeName = "Catppuccin Mocha";
  driverLibraryArg = "--set LD_LIBRARY_PATH /run/opengl-driver/lib:";
  rewriteWrapperArg = arg:
    if lib.hasPrefix "--set NIX_LAUNCHER_WRAPPER " arg
    then null
    else if lib.hasPrefix driverLibraryArg arg
    then "--suffix LD_LIBRARY_PATH : ${lib.removePrefix driverLibraryArg arg}"
    else arg;
  prismLauncherPackage = config.dotfiles.graphical.nixgl.maybeWrap {
    package = pkgs.prismlauncher.overrideAttrs (old: {
      # Keep child launches on the outer wrapper and append Prism's runtime
      # libraries behind nixGL's coherent Mesa stack.
      qtWrapperArgs = builtins.filter (arg: arg != null) (map rewriteWrapperArg old.qtWrapperArgs);
    });
    bin = "prismlauncher";
    launcherWrapper = true;
  };
in {
  home.packages = [pkgs.mcaselector];

  programs.prismlauncher = {
    enable = true;
    package = prismLauncherPackage;

    settings = {
      # keep-sorted start
      ApplicationTheme = themeName;
      InstSortMode = "Name";
      InstanceDir = "${config.home.homeDirectory}/Games/prismlauncher";
      MaxMemAlloc = 4096;
      MinMemAlloc = 2048;
      ShowConsole = true;
      # keep-sorted end
    };

    themes.${themeName} = {
      theme = {
        name = themeName;
        widgets = "Fusion";
        colors = {
          # keep-sorted start
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
          # keep-sorted end
        };
        logColors = {
          # keep-sorted start
          Debug = "#a6e3a1";
          Error = "#f38ba8";
          Fatal = "#181825";
          FatalHighlight = "#f38ba8";
          Launcher = "#cba6f7";
          Warning = "#f9e2af";
          # keep-sorted end
        };
      };
      style = ''
        QToolTip {
          color: #cdd6f4;
          background-color: #313244;
          border: 1px solid #313244;
        }
      '';
    };
  };
}
