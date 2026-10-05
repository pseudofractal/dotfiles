{
  isAndroid,
  lib,
  pkgs,
  ...
}: let
  nchatWithPng = pkgs.nchat.overrideAttrs (old: {
    buildInputs = old.buildInputs ++ [pkgs.libpng];
  });
in
  lib.mkIf (!isAndroid) {
    home.packages = with pkgs; [
      (aspellWithDicts (dicts: [dicts.en]))
      libnotify
      nchatWithPng
      wl-clipboard
      xdg-utils
    ];

    xdg.configFile = {
      "nchat/app.conf" = {
        force = true;
        text = ''
          clipboard_copy_command=${lib.getExe' pkgs.wl-clipboard "wl-copy"}
          clipboard_has_image_command=${lib.getExe' pkgs.wl-clipboard "wl-paste"} --list-types | ${lib.getExe pkgs.gnugrep} -m1 'image/png' | ${lib.getExe' pkgs.coreutils "wc"} -l
          clipboard_paste_command=${lib.getExe' pkgs.wl-clipboard "wl-paste"} --no-newline
          clipboard_paste_image_command=${lib.getExe' pkgs.wl-clipboard "wl-paste"} --type image/png
        '';
      };

      "nchat/ui.conf" = {
        force = true;
        text = ''
          attachment_open_command=${lib.getExe' pkgs.xdg-utils "xdg-open"} >/dev/null 2>&1 '%1' &
          desktop_notify_command=${lib.getExe' pkgs.libnotify "notify-send"} 'nchat' '%1: %2'
          desktop_notify_enabled=1
          linefeed_on_enter=0
          link_open_command=${lib.getExe' pkgs.xdg-utils "xdg-open"} >/dev/null 2>&1 '%1' &
          list_width=20
          message_edit_command=${lib.getExe pkgs.neovim}
          message_open_command=${lib.getExe pkgs.bat} --paging=always --style=plain
          terminal_title=nchat
        '';
      };

      "nchat/key.conf" = {
        force = true;
        text = ''
          auto_compose=KEY_NONE
          clear=\33\143
          copy=KEY_CTRLC
          cut=KEY_CTRLX
          delete=KEY_NONE
          delete_chat=KEY_SDC
          delete_line_before_cursor=KEY_NONE
          delete_msg=KEY_DC
          end_line=KEY_NONE
          ext_edit=KEY_NONE
          forward_msg=KEY_CTRLF
          linebreak=\33\15
          open=\33\157
          open_link=\33\154
          open_msg=\33\155
          other_commands_help=KEY_NONE
          paste=KEY_CTRLV
          react=KEY_CTRLE
          save=KEY_CTRLO
          select_emoji=\33\145
          select_mention=\33\62
          send_msg=KEY_RETURN
          transfer=\33\151
          unread_chat=KEY_CTRLU
        '';
      };

      "nchat/color.conf" = {
        force = true;
        text = ''
          default_color_bg=0x1e1e2e
          default_color_fg=0xcdd6f4
          dialog_attr=
          dialog_attr_selected=reverse
          dialog_color_bg=
          dialog_color_fg=0xbac2de
          dialog_shaded_color_bg=
          dialog_shaded_color_fg=gray
          entry_attr=
          entry_color_bg=
          entry_color_fg=
          help_attr=
          help_color_bg=0x585b70
          help_color_fg=0xbac2de
          history_name_attr=bold
          history_name_attr_selected=reverse
          history_name_recv_color_bg=
          history_name_recv_color_fg=0x89b4fa
          history_name_recv_group_color_bg=
          history_name_recv_group_color_fg=usercolor
          history_name_sent_color_bg=
          history_name_sent_color_fg=0xf5c2e7
          history_text_attachment_color_bg=
          history_text_attachment_color_fg=0xbac2de
          history_text_attr=
          history_text_attr_selected=reverse
          history_text_quoted_color_bg=
          history_text_quoted_color_fg=0xbac2de
          history_text_reaction_color_bg=0x2e2e3e
          history_text_reaction_color_fg=gray
          history_text_recv_color_bg=
          history_text_recv_color_fg=
          history_text_recv_group_color_bg=
          history_text_recv_group_color_fg=
          history_text_sent_color_bg=
          history_text_sent_color_fg=
          list_attr=
          list_attr_selected=reverse
          list_color_bg=
          list_color_fg=0xbac2de
          list_color_unread_bg=
          list_color_unread_fg=0xbac2de
          listborder_attr=
          listborder_color_bg=
          listborder_color_fg=0xbac2de
          status_attr=
          status_color_bg=0x585b70
          status_color_fg=0x89b4fa
          top_attr=
          top_color_bg=0x585b70
          top_color_fg=0xbac2de
        '';
      };

      "nchat/usercolor.conf" = {
        force = true;
        text = ''
          0xf38ba8
          0xa6e3a1
          0xf9e2af
          0x89b4fa
          0x94e2d5
          0xf38ba8
          0xa6e3a1
          0xf9e2af
          0x89b4fa
          0xf5c2e7
          0x94e2d5
          0xa6adc8
        '';
      };
    };

    xdg.dataFile = {
      "applications/nchat.desktop".text = ''
        [Desktop Entry]
        Name=nchat
        Comment=WhatsApp and email
        Exec=kitty --app-id=nchat nchat
        Icon=nchat
        Terminal=false
        Type=Application
        Categories=Network;Chat;Email;
        StartupWMClass=nchat
      '';
      "icons/hicolor/scalable/apps/nchat.svg".source = ./nchat.svg;
    };
  }
