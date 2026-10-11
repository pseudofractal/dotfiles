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
        run_advance_alt = "<leader>jr",
        run_all = "<leader>jR",
        run_above = "<leader>jA",
        run_below = "<leader>jB",
        add_above = "<leader>ja",
        add_below = "<leader>jb",
        delete_cell = "<leader>jd",
        move_up = "<leader>jk",
        move_down = "<leader>jj",
        to_markdown = "<leader>jm",
        to_code = "<leader>jy",
        pick_kernel = "<leader>jK",
        start_kernel = "<leader>js",
        stop_kernel = "<leader>jS",
        interrupt_kernel = "<leader>ji",
        restart_kernel = "<leader>jx",
        expand_output = "<leader>jo",
        hide_output = "<leader>jO",
        limit_output = "<leader>jl",
        clear_output = "<leader>jc",
        clear_all = "<leader>jC",
        save_image = "<leader>jI",
        delete_image = "<leader>jD",
        refresh = "<leader>jL",
      },
    })
  end,
}
