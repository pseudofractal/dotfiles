{
  pkgs,
  lib,
  config,
  ...
}: let
  okular = config.dotfiles.graphical.nixgl.maybeWrap {
    package = pkgs.kdePackages.okular;
    bin = "okular";
  };
  sioyek = config.dotfiles.graphical.nixgl.maybeWrap {
    package = pkgs.sioyek;
    bin = "sioyek";
  };
  detachedSioyek = pkgs.symlinkJoin {
    name = "sioyek-detached";
    paths = [sioyek];
    postBuild = ''
      rm -f "$out/bin/sioyek"
      cat > "$out/bin/sioyek" <<EOF
      #!${pkgs.runtimeShell}
      exec ${pkgs.util-linux}/bin/setsid -f ${lib.getExe' sioyek "sioyek"} "\$@" </dev/null >/dev/null 2>&1
      EOF
      chmod +x "$out/bin/sioyek"
    '';
  };
in {
  home.packages = with pkgs; [
    # keep-sorted start
    diffpdf
    ghostscript
    okular
    pdfarranger
    # keep-sorted end
  ];

  programs.sioyek = {
    enable = true;
    package = detachedSioyek;
    config = {
      "ui_font" = "Maple Mono NF CN";
      "status_bar_font_size" = "16";
      "font_size" = "14";
      "startup_commands" = [
        "toggle_custom_color"
        "toggle_horizontal_scroll_lock"
        "fit_to_page_width"
      ];
      "show_doc_path" = "1";
      "single_click_selects_words" = "1";
      "create_table_of_contents_if_not_exists" = "1";
      "max_created_toc_size" = "5000";
      "should_launch_new_window" = "1";
    };
    bindings = {
      "close_window" = "q";
      "command" = "<C-p>";
      "toggle_custom_color" = "<C-d>";
    };
  };

  xdg.mimeApps.defaultApplications = {
    "application/pdf" = ["sioyek.desktop"];
  };
}
