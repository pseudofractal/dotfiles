{...}: {
  programs.nvf.settings.vim.utility.yazi-nvim = {
    enable = true;
    mappings = {
      openYazi = null;
      openYaziDir = null;
      yaziToggle = null;
    };
    setupOpts = {
      open_for_directories = false;
      keymaps.show_help = "<f1>";
      floating_window_scaling_factor = 0.95;
    };
  };
}
