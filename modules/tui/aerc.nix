{
  config,
  lib,
  pkgs,
  ...
}: {
  accounts.email.accounts = {
    "Gmail (IISER)" = {
      address = "ms22174@iisermohali.ac.in";
      userName = "ms22174@iisermohali.ac.in";
      realName = "Kshitish Kumar Ratha";
      primary = true;
      passwordCommand = [
        "${pkgs.coreutils}/bin/cat"
        config.sops.secrets."mail/app-passwords/google/iiser".path
      ];

      imap = {
        host = "imap.gmail.com";
        port = 993;
        tls.enable = true;
      };
      smtp = {
        host = "smtp.gmail.com";
        port = 465;
        tls.enable = true;
      };
      folders = {
        inbox = "INBOX";
        sent = null;
        drafts = "[Gmail]/Drafts";
        trash = "[Gmail]/Trash";
      };
      aerc = {
        enable = true;
        extraAccounts = {
          "cache-headers" = true;
        };
      };
    };

    "Gmail (Personal)" = {
      address = "kshitishkumarratha@gmail.com";
      userName = "kshitishkumarratha@gmail.com";
      realName = "Kshitish Kumar Ratha";
      passwordCommand = [
        "${pkgs.coreutils}/bin/cat"
        config.sops.secrets."mail/app-passwords/google/personal".path
      ];

      imap = {
        host = "imap.gmail.com";
        port = 993;
        tls.enable = true;
      };
      smtp = {
        host = "smtp.gmail.com";
        port = 465;
        tls.enable = true;
      };
      folders = {
        inbox = "INBOX";
        sent = null;
        drafts = "[Gmail]/Drafts";
        trash = "[Gmail]/Trash";
      };
      aerc = {
        enable = true;
        extraAccounts = {
          "cache-headers" = true;
        };
      };
    };
  };

  home.file."${config.xdg.configHome}/aerc/binds.conf" = {
    force = true;
    text =
      lib.replaceStrings
      ["[messages]\n"]
      ["[messages]\nRd = :read<Enter>\n"]
      (builtins.readFile "${config.programs.aerc.package}/share/aerc/binds.conf");
  };

  programs.aerc = {
    enable = true;
    extraConfig = {
      compose.editor = lib.getExe pkgs.neovim;
      general.unsafe-accounts-conf = true;
      viewer.pager = "${lib.getExe pkgs.bat} --paging=always --pager=builtin --style=plain --color=always --strip-ansi=never";
      filters = {
        ".headers" = "colorize";
        "message/delivery-status" = "colorize";
        "message/rfc822" = "colorize";
        "text/calendar" = "calendar";
        "text/html" = "! html";
        "text/plain" = "colorize";
      };
    };
    stylesets."catppuccin-mocha" = lib.mkForce ''
      *.default=true
      *.normal=true

      default.fg=#cdd6f4
      default.bg=#1e1e2e

      title.fg=#89b4fa
      title.bg=#1e1e2e
      title.bold=true

      error.fg=#f38ba8
      warning.fg=#fab387
      success.fg=#a6e3a1

      tab.fg=#a6adc8
      tab.bg=#313244
      tab.selected.fg=#1e1e2e
      tab.selected.bg=#89b4fa
      tab.selected.bold=true

      border.fg=#585b70
      border.bold=true

      msglist_default.fg=#cdd6f4
      msglist_default.bg=#1e1e2e
      msglist_read.fg=#bac2de
      msglist_unread.fg=#f5c2e7
      msglist_unread.bold=true
      msglist_deleted.fg=#f38ba8
      msglist_flagged.fg=#f9e2af
      msglist_flagged.bold=true
      msglist_marked.fg=#1e1e2e
      msglist_marked.bg=#94e2d5
      msglist_result.fg=#89b4fa
      msglist_result.bold=true
      msglist_*.selected.fg=#1e1e2e
      msglist_*.selected.bg=#89b4fa
      msglist_*.selected.bold=true

      dirlist_default.fg=#cdd6f4
      dirlist_default.bg=#1e1e2e
      dirlist_unread.fg=#94e2d5
      dirlist_*.selected.fg=#1e1e2e
      dirlist_*.selected.bg=#94e2d5
      dirlist_*.selected.bold=true

      statusline_default.fg=#cdd6f4
      statusline_default.bg=#313244
      statusline_error.fg=#f38ba8
      statusline_warning.fg=#fab387
      statusline_success.fg=#a6e3a1
      statusline_error.bold=true
      statusline_success.bold=true

      selector_focused.fg=#cdd6f4
      selector_focused.bg=#45475a
      completion_default.fg=#cdd6f4
      completion_default.bg=#313244
      completion_default.selected.fg=#1e1e2e
      completion_default.selected.bg=#cba6f7

      part_switcher.fg=#cdd6f4
      part_switcher.bg=#313244
      part_switcher.selected.fg=#1e1e2e
      part_switcher.selected.bg=#cba6f7
      part_switcher.selected.bold=true
      part_filename.fg=#f9e2af
      part_filename.bg=#313244
      part_filename.selected.fg=#1e1e2e
      part_filename.selected.bg=#cba6f7
      part_mimetype.fg=#89b4fa
      part_mimetype.bg=#313244
      part_mimetype.selected.fg=#1e1e2e
      part_mimetype.selected.bg=#cba6f7

      [viewer]
      url.fg=#89b4fa
      url.underline=true
      header.fg=#89b4fa
      header.bold=true
      signature.fg=#9399b2
      signature.dim=true
      diff_meta.fg=#cba6f7
      diff_meta.bold=true
      diff_chunk.fg=#89b4fa
      diff_chunk_func.fg=#89b4fa
      diff_chunk_func.bold=true
      diff_add.fg=#a6e3a1
      diff_del.fg=#f38ba8
      diff_whitespace.bg=#f38ba8
      quote_*.fg=#6c7086
      quote_1.fg=#9399b2
    '';
  };
}
