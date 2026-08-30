{
  config,
  pkgs,
  ...
}: let
  themeName = "Catppuccin Mocha";
  prismLauncherPackage = let
    prismLauncherUnwrapped = pkgs.prismlauncher-unwrapped;

    runtimeLibraryPath = pkgs.lib.makeLibraryPath [
      prismLauncherUnwrapped

      # keep-sorted start
      pkgs.alsa-lib
      pkgs.flite
      pkgs.gamemode
      pkgs.gcc.cc.lib
      pkgs.glfw3-minecraft
      pkgs.libGL
      pkgs.libdecor
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
      pkgs.udev
      pkgs.vulkan-loader
      pkgs.wayland
      # keep-sorted end
    ];

    qtPluginPaths = pkgs.lib.makeSearchPath "lib/qt-6/plugins" [
      pkgs.qt6.qtbase
      pkgs.qt6.qtdeclarative
      pkgs.qt6.qtimageformats
      pkgs.qt6.qtsvg
      pkgs.qt6.qtwayland
    ];

    qtQmlImportPaths = pkgs.lib.makeSearchPath "lib/qt-6/qml" [
      pkgs.qt6.qtdeclarative
      pkgs.qt6.qtwayland
    ];

    runtimeProgramPath = pkgs.lib.makeBinPath [
      pkgs.pciutils
      pkgs.xrandr
    ];

    javaSearchPath = pkgs.lib.makeSearchPath "bin/java" [
      pkgs.jdk8
      pkgs.jdk11
      pkgs.jdk17
      pkgs.jdk21
      pkgs.jdk25
    ];

    prismLauncherScript = pkgs.writeShellScriptBin "prismlauncher" ''
      gfxMode=""
      if command -v supergfxctl >/dev/null 2>&1; then
        gfxMode="$(supergfxctl --get 2>/dev/null || true)"
      fi
      if [ "$gfxMode" = "Hybrid" ]; then
        unset GBM_BACKENDS_PATH
        unset LIBGL_DRIVERS_PATH
        unset LIBVA_DRIVERS_PATH
        unset __EGL_VENDOR_LIBRARY_FILENAMES
        export __GLX_VENDOR_LIBRARY_NAME=nvidia
        export __NV_PRIME_RENDER_OFFLOAD=1
        export __VK_LAYER_NV_optimus=NVIDIA_only
        export VK_LOADER_DRIVERS_SELECT='*nvidia*'
        export LD_LIBRARY_PATH="${runtimeLibraryPath}:/usr/lib:/usr/lib64''${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
      else
        unset __GLX_VENDOR_LIBRARY_NAME
        unset __NV_PRIME_RENDER_OFFLOAD
        unset __VK_LAYER_NV_optimus
        unset VK_LOADER_DRIVERS_SELECT
        if [ -n "$LD_LIBRARY_PATH" ]; then
          export LD_LIBRARY_PATH="${runtimeLibraryPath}:/usr/lib:/usr/lib64:$LD_LIBRARY_PATH"
        else
          export LD_LIBRARY_PATH="${runtimeLibraryPath}:/usr/lib:/usr/lib64"
        fi
      fi
      if [ -n "$PATH" ]; then
        export PATH="${runtimeProgramPath}:$PATH"
      else
        export PATH="${runtimeProgramPath}"
      fi
      if [ -n "$QT_PLUGIN_PATH" ]; then
        export QT_PLUGIN_PATH="${qtPluginPaths}:$QT_PLUGIN_PATH"
      else
        export QT_PLUGIN_PATH="${qtPluginPaths}"
      fi
      if [ -n "$NIXPKGS_QT6_QML_IMPORT_PATH" ]; then
        export NIXPKGS_QT6_QML_IMPORT_PATH="${qtQmlImportPaths}:$NIXPKGS_QT6_QML_IMPORT_PATH"
      else
        export NIXPKGS_QT6_QML_IMPORT_PATH="${qtQmlImportPaths}"
      fi
      if [ -n "$XDG_DATA_DIRS" ]; then
        export XDG_DATA_DIRS="${pkgs.prismlauncher}/share:/usr/local/share:/usr/share:$XDG_DATA_DIRS"
      else
        export XDG_DATA_DIRS="${pkgs.prismlauncher}/share:/usr/local/share:/usr/share"
      fi
      export PRISMLAUNCHER_JAVA_PATHS="${javaSearchPath}"
      export NIX_LAUNCHER_WRAPPER="$0"

      exec ${prismLauncherUnwrapped}/bin/prismlauncher "$@"
    '';
  in
    pkgs.symlinkJoin {
      name = "prismlauncher";

      paths = [pkgs.prismlauncher];

      postBuild = ''
        rm -f "$out/bin/prismlauncher"
        ln -s ${prismLauncherScript}/bin/prismlauncher "$out/bin/prismlauncher"
      '';
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
