{
  config,
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
      aapt
      asciinema
      bat
      catdoc
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
      pandoc
      poppler-utils
      resvg
      ripdrag
      sqlite
      starship
      trash-cli
      tree
      transmission_4
      ueberzugpp
      unar
      woff2
      (python313.withPackages (p: [
        p.nbconvert
        p.xlsx2csv
      ]))
      # keep-sorted end
    ];
  };

  catppuccin.yazi.enable = true;

  home.packages = [pkgs.xdg-terminal-exec];

  xdg.portal = {
    enable = true;
    extraPortals = [
      pkgs.xdg-desktop-portal-gtk
      pkgs.xdg-desktop-portal-termfilechooser
    ];
    config.common = {
      default = ["gtk"];
      "org.freedesktop.impl.portal.FileChooser" = ["termfilechooser"];
    };
  };

  xdg.configFile."xdg-desktop-portal-termfilechooser/config".text = ''
    [filechooser]
    cmd=${pkgs.xdg-desktop-portal-termfilechooser}/share/xdg-desktop-portal-termfilechooser/yazi-wrapper.sh
    default_dir=$HOME
    env=TERMCMD=kitty
  '';
}
