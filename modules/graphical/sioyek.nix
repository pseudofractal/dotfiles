{pkgs, ...}: {
  home.packages = with pkgs; [
    pdfarranger
    diffpdf
    ghostscript
  ];

  programs.sioyek = {
    enable = false;
    config = {
      "ui_font" = "Maple Mono NF CN";
      "status_bar_font_size" = "16";
      "font_size" = "14";
      "startup_commands" = "toggle_custom_color;toggle_horizontal_scroll_lock;fit_to_page_width";
      "create_table_of_contents_if_not_exists" = "1";
      "max_created_toc_size" = "5000";
      "should_launch_new_window" = "1";
    };
    bindings = {
      "close_window" = "q";
      "command" = "<C-p>";
    };
  };

  xdg.mimeApps.defaultApplications = {
    "application/pdf" = ["sioyek.desktop"];
  };
}
