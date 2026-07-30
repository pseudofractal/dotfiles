return {
  "akinsho/bufferline.nvim",
  version = "*",
  lazy = false,
  dependencies = {
    {
      "echasnovski/mini.icons",
      config = function()
        require("mini.icons").setup()
        MiniIcons.mock_nvim_web_devicons()
      end,
    },
    "folke/snacks.nvim",
  },
  opts = {
    options = {
      close_command = function(n)
        Snacks.bufdelete(n)
      end,
      right_mouse_command = function(n)
        Snacks.bufdelete(n)
      end,
    },
  },
  keys = {
    { "<S-Tab>", "<cmd>BufferLineCyclePrev<cr>", desc = "Previous Buffer" },
    { "<leader>tp", "<Cmd>BufferLineTogglePin<CR>", desc = "Toggle Pin" },
    { "<leader>td", "<Cmd>BufferLineGroupClose ungrouped<CR>", desc = "Delete Non-Pinned Buffers" },
  },
}
