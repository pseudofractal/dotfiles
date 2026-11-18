return {
  "sheng-tse/jupynvim",
  build = function(plugin)
    local install = loadfile(plugin.dir .. "/lua/jupynvim/install.lua")()
    install.run(plugin)
  end,
  config = function()
    require("jupynvim").setup({
      image_renderer = "placeholder",
      keymaps = {
        run_advance_alt = "<leader>nr",
        run_all = "<leader>nR",
        run_above = "<leader>nA",
        run_below = "<leader>nB",
        add_above = "<leader>na",
        add_below = "<leader>nb",
        delete_cell = "<leader>nd",
        move_up = "<leader>nk",
        move_down = "<leader>nj",
        to_markdown = "<leader>nm",
        to_code = "<leader>ny",
        pick_kernel = "<leader>nK",
        start_kernel = "<leader>ns",
        stop_kernel = "<leader>nS",
        interrupt_kernel = "<leader>ni",
        restart_kernel = "<leader>nx",
        expand_output = "<leader>no",
        hide_output = "<leader>nO",
        limit_output = "<leader>nl",
        clear_output = "<leader>nc",
        clear_all = "<leader>nC",
        save_image = "<leader>nI",
        delete_image = "<leader>nD",
        refresh = "<leader>nL",
      },
    })
  end,
}
