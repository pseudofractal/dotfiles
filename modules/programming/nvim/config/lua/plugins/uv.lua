return {
  "benomahony/uv.nvim",
  config = function()
    require("uv").setup({
      keymaps = { prefix = "<leader>xp" },
    })
  end,
}
