return {
  "folke/which-key.nvim",
  event = "VeryLazy",
  opts = {
    spec = {
      { "<leader>c", group = "Code Actions" },
      { "<leader>d", group = "Debug & Diagnostics" },
      { "<leader>f", group = "Find" },
      { "<leader>g", group = "Git & Goto" },
      { "<leader>gh", group = "Git Hunk" },
      { "<leader>j", group = "Jupyter" },
      { "<leader>l", group = "LSP" },
      { "<leader>o", group = "Notes" },
      { "<leader>u", group = "UI" },
      { "<leader>w", group = "Windows & Buffers" },
      { "<leader>L", group = "Language" },
      { "<leader>Lp", group = "Python" },
      { "z", group = "Code Folding" },
    },
  },
  keys = {
    {
      "<leader>?",
      function()
        require("which-key").show({ global = false })
      end,
      desc = "Buffer Local Keymaps (which-key)",
    },
  },
}
