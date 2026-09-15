return {
  "folke/noice.nvim",
  event = "VeryLazy",
  dependencies = {
    "MunifTanjim/nui.nvim",
    "rcarriga/nvim-notify",
  },
  config = function()
    require("notify").setup({
      background_colour = "#000000",
    })
    require("noice").setup({
      views = {
        cmdline_popup = {
          position = { row = "50%", col = "50%" },
        },
        cmdline_popupmenu = {
          position = { row = "55%", col = "50%" },
        },
        cmdline_input = {
          position = { row = "50%", col = "50%" },
        },
        confirm = {
          position = { row = "50%", col = "50%" },
        },
      },
      lsp = {
        override = {
          ["vim.lsp.util.convert_input_to_markdown_lines"] = true,
          ["vim.lsp.util.stylize_markdown"] = true,
        },
      },
      popupmenu = { enabled = false },
      presets = {
        bottom_search = true,
        command_palette = true,
        long_message_to_split = true,
        lsp_doc_border = true,
      },
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
