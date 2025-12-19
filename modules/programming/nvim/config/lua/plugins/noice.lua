return {
  "folke/noice.nvim",
  dependencies = {
    "MunifTanjim/nui.nvim",
    "rcarriga/nvim-notify",
  },
  event = "VeryLazy",
  config = function()
    require("noice").setup({})
    require("notify").setup({
      background_colour = "#000000",
      timeout = 5000,
    })
  end,
  keys = {
    {
      "<leader>DD",
      "<cmd>Noice dismiss<cr>",
      desc = "Dismiss all notifications.",
    },
  },
}
