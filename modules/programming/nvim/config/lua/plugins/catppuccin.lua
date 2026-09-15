return {
  "catppuccin/nvim",
  name = "catppuccin",
  lazy = false,
  priority = 1000,
  config = function()
    require("catppuccin").setup({
      flavour = "mocha",
      transparent_background = true,
      integrations = {
        blink_cmp = true,
        dap = true,
        gitsigns = true,
        mini = true,
        native_lsp = true,
        noice = true,
        snacks = true,
        treesitter = true,
        which_key = true,
      },
      custom_highlights = function(colors)
        return {
          ["@markup.list.checked.markdown"] = { bg = colors.green, fg = colors.mantle },
          ["@markup.list.unchecked.markdown"] = { bg = colors.red, fg = colors.mantle },
          SnacksIndent1 = { fg = colors.rosewater },
          SnacksIndent2 = { fg = colors.lavender },
          SnacksIndent3 = { fg = colors.flamingo },
          SnacksIndent4 = { fg = colors.blue },
          SnacksIndent5 = { fg = colors.pink },
          SnacksIndent6 = { fg = colors.sapphire },
          SnacksIndent7 = { fg = colors.mauve },
          SnacksIndent8 = { fg = colors.teal },
          SnacksIndent9 = { fg = colors.red },
          SnacksIndent10 = { fg = colors.green },
        }
      end,
    })
    vim.cmd([[colorscheme catppuccin]])
  end,
}
