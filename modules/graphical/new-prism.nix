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

  themeCss = pkgs.writeText "prismlauncher-catppuccin-mocha-theme.css" ''
    QToolTip {
      color: #cdd6f4;
      background-color: #313244;
      border: 1px solid #313244;
    }
  '';

  wrappedPrismLauncher = let
    unwrapped = builtins.head pkgs.prismlauncher.paths;

    runtimeLibs = pkgs.lib.makeLibraryPath [
      unwrapped

      # keep-sorted start
      pkgs.alsa-lib
      pkgs.flite
      pkgs.gamemode
      pkgs.gcc.cc.lib
      pkgs.glfw3-minecraft
      pkgs.libglvnd
      pkgs.libjack2
      pkgs.libpulseaudio
      pkgs.libusb1
      pkgs.libx11
      pkgs.libxcursor
      pkgs.libxext
      pkgs.libxrandr
      pkgs.libxxf86vm
      pkgs.openal
      pkgs.pipewire
      pkgs.qt6.qtbase
      pkgs.qt6.qtdeclarative
      pkgs.qt6.qtimageformats
      pkgs.qt6.qtsvg
      pkgs.qt6.qtwayland
      pkgs.systemdMinimal
      pkgs.vulkan-loader
      # keep-sorted end
    ];

    javaPaths = pkgs.lib.makeSearchPath "bin/java" [
      pkgs.jdk8
      pkgs.jdk11
      pkgs.jdk17
      pkgs.jdk21
      pkgs.jdk25
    ];
  in
    pkgs.symlinkJoin {
      name = "prismlauncher";

      paths = [pkgs.prismlauncher];

      nativeBuildInputs = [pkgs.makeWrapper];

      postBuild = ''
                rm -f "$out/bin/prismlauncher"

                cat >"$out/bin/prismlauncher" <<EOF
        #!${pkgs.runtimeShell}

        export LD_LIBRARY_PATH="${runtimeLibs}"''${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}:/usr/lib:/usr/lib64
        export QT_PLUGIN_PATH="${pkgs.qt6.qtbase}/lib/qt-6/plugins"''${QT_PLUGIN_PATH:+:$QT_PLUGIN_PATH}
        export PRISMLAUNCHER_JAVA_PATHS="${javaPaths}"

        exec ${unwrapped}/bin/prismlauncher "\$@"
        EOF

                chmod +x "$out/bin/prismlauncher"
      '';
    };
in {
  home.packages = [ pkgs.mcaselector ];

  programs.prismlauncher = {
    enable = true;
    package = wrappedPrismLauncher;

    settings = {
      # keep-sorted start
      ApplicationTheme = themeName;
      InstSortMode = "Name";
      MaxMemAlloc = 4096;
      MinMemAlloc = 2048;
      ShowConsole = true;
      # keep-sorted end
    };
  };

  # keep-sorted start
  xdg.dataFile."${themeDir}/resources/.keep".text = "";
  xdg.dataFile."${themeDir}/theme.json".source = themeJson;
  xdg.dataFile."${themeDir}/themeStyle.css".source = themeCss;
  # keep-sorted end
}
