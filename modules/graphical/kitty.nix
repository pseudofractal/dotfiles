{
  pkgs,
  lib,
  config,
  inputs,
  isNixOS,
  ...
}: let
  nixgl = import ./nixgl-helper.nix {
    inherit config lib pkgs inputs isNixOS;
  };
in {
  programs.kitty = {
    enable = true;
    package = nixgl.maybeWrap {
      package = pkgs.kitty;
      bin = "kitty";
    };

    settings = {
      font_family = "maple mono";
      font_size = "15.0";
      bold_font = "auto";
      italic_font = "auto";
      bold_italic_font = "auto";

      cursor_shape = "block";
      mouse_hide_wait = "2.0";

      url_color = "#94e2d5";
      url_style = "dotted";

      confirm_os_window_close = 0;
      background_opacity = "0.9";

      enabled_layouts = "splits,stack";

      allow_remote_control = "yes";
      listen_on = "unix:@mykitty";
      shell_integration = "enabled";
    };

    keybindings = {
      "ctrl+r" = "set_tab_title";
      f1 = "set_tab_title Code Editor";
      f2 = "set_tab_title CLI";
      f3 = "set_tab_title Runners";
      "shift+ctrl+r" = "set_tab_title \"\"";
    };
  };
}
