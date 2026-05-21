{...}: {
  programs.nvf.settings.vim = {
    telescope = {
      enable = true;
      setupOpts = {
        defaults = {
          layout_strategy = "vertical";
          sorting_strategy = "ascending";
        };
      };
    };
  };
}
