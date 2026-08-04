{
  isAndroid,
  lib,
  pkgs,
  ...
}: {
  programs.yazi.plugins = lib.mkIf (!isAndroid) {
    # keep-sorted start
    bunny = pkgs.yaziPlugins.bunny;
    custom-shell = pkgs.yaziPlugins.custom-shell;
    enhance-piper = pkgs.yaziPlugins.enhance-piper;
    file-extra-metadata = pkgs.yaziPlugins.file-extra-metadata;
    git = pkgs.yaziPlugins.git;
    gvfs = pkgs.yaziPlugins.gvfs;
    jump-to-char = pkgs.yaziPlugins.jump-to-char;
    mediainfo = pkgs.yaziPlugins.mediainfo;
    mount = pkgs.yaziPlugins.mount;
    office = pkgs.yaziPlugins.office;
    ouch = pkgs.yaziPlugins.ouch;
    piper = pkgs.yaziPlugins.piper;
    restore = pkgs.yaziPlugins.restore;
    smart-enter = pkgs.yaziPlugins.smart-enter;
    smart-filter = pkgs.yaziPlugins.smart-filter;
    starship = pkgs.yaziPlugins.starship;
    toggle-pane = pkgs.yaziPlugins.toggle-pane;
    what-size = pkgs.yaziPlugins.what-size;
    # keep-sorted end
  };
}
