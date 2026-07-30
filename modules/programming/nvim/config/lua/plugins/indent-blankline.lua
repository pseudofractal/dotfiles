return {
  "lukas-reineke/indent-blankline.nvim",
  config = function()
    local highlight = {
      "RainbowRosewater",
      "RainbowLavender",
      "RainbowFlamingo",
      "RainbowBlue",
      "RainbowPink",
      "RainbowSapphire",
      "RainbowMauve",
      "RainbowTeal",
      "RainbowRed",
      "RainbowGreen",
    }

    local hooks = require("ibl.hooks")
    hooks.register(hooks.type.HIGHLIGHT_SETUP, function()
      vim.api.nvim_set_hl(0, "RainbowRosewater", { fg = "#F5E0DC" })
      vim.api.nvim_set_hl(0, "RainbowLavender", { fg = "#B4BEFE" })
      vim.api.nvim_set_hl(0, "RainbowFlamingo", { fg = "#F2CDCD" })
      vim.api.nvim_set_hl(0, "RainbowBlue", { fg = "#89B4FA" })
      vim.api.nvim_set_hl(0, "RainbowPink", { fg = "#F5C2E7" })
      vim.api.nvim_set_hl(0, "RainbowSapphire", { fg = "#74C7EC" })
      vim.api.nvim_set_hl(0, "RainbowMauve", { fg = "#CBA6F7" })
      vim.api.nvim_set_hl(0, "RainbowTeal", { fg = "#94E2D5" })
      vim.api.nvim_set_hl(0, "RainbowRed", { fg = "#F38BA8" })
      vim.api.nvim_set_hl(0, "RainbowGreen", { fg = "#A6E3A1" })
    end)

    require("ibl").setup({
      indent = { highlight = highlight },
      scope = { enabled = false },
    })
  end,
}
