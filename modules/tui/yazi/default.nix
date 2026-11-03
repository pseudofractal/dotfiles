{
  config,
  isAndroid,
  lib,
  pkgs,
  inputs,
  ...
}: {
  nixpkgs.overlays = [inputs.nur-vortriz.overlays.yaziPlugins];

  imports = [
    # keep-sorted start
    ./keymap.nix
    ./plugins.nix
    ./settings.nix
    # keep-sorted end
  ];

  programs.yazi = {
    enable = true;
    enableFishIntegration = true;
    shellWrapperName = "y";
    initLua = ./init.lua;
    extraPackages = with pkgs; [
      # keep-sorted start
      (python313.withPackages (p: [
        p.nbconvert
        p.xlsx2csv
      ]))
      aapt
      asciinema
      bat
      catdoc
      duckdb
      exiftool
      ffmpeg
      ffmpegthumbnailer
      file
      fish
      fzf
      git
      glib
      glow
      imagemagick
      jq
      libreoffice
      mediainfo
      miller
      ouch
      p7zip
      pandoc
      poppler-utils
      resvg
      ripdrag
      sqlite
      starship
      transmission_4
      trash-cli
      tree
      ueberzugpp
      unar
      woff2
      # keep-sorted end
    ];
  };

  catppuccin.yazi.enable = true;

  home.packages = [pkgs.xdg-terminal-exec];

  # GUI applications open directories through xdg-open, which ignores the
  # Terminal=true key in the packaged Yazi entry and starts Yazi without a TTY.
  # Launch it through a terminal explicitly instead.
  xdg.dataFile."applications/yazi.desktop".text = ''
    [Desktop Entry]
    Name=Yazi File Manager
    Comment=Blazing fast terminal file manager written in Rust, based on async I/O
    Icon=yazi
    Terminal=false
    TryExec=yazi
    Exec=xdg-terminal-exec yazi %f
    Type=Application
    MimeType=inode/directory
    Categories=System;FileManager;FileTools;ConsoleOnly
    Keywords=File;Manager;Explorer;Browser;Launcher
  '';

  xdg.portal = lib.mkIf (!isAndroid) {
    enable = true;
    extraPortals = [
      # keep-sorted start
      pkgs.xdg-desktop-portal-gtk
      pkgs.xdg-desktop-portal-termfilechooser
      # keep-sorted end
    ];
    config.common = {
      default = ["gtk"];
      "org.freedesktop.impl.portal.FileChooser" = ["termfilechooser"];
    };
  };

  xdg.configFile."xdg-desktop-portal-termfilechooser/config" = lib.mkIf (!isAndroid) {
    text = ''
      [filechooser]
      cmd=${pkgs.xdg-desktop-portal-termfilechooser}/share/xdg-desktop-portal-termfilechooser/yazi-wrapper.sh
      default_dir=$HOME
      env=TERMCMD=kitty
    '';
  };
}
