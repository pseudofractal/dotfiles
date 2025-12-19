return {
  "catppuccin/nvim",
  name = "catppuccin",
  lazy = false,
  priority = 1000,
  config = function()
    require("catppuccin").setup({
      flavour = "mocha",
      transparent_background = true,
      custom_highlights = function(colors)
        return {
          ["@markup.list.checked.markdown"] = { bg = colors.green, fg = colors.mantle },
          ["@markup.list.unchecked.markdown"] = { bg = colors.red, fg = colors.mantle },
        }
      end,
    })
    vim.cmd([[colorscheme catppuccin]])
  end,
}
