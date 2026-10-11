return {
  "folke/which-key.nvim",
  event = "VeryLazy",
  opts = {
    spec = {
      -- keep-sorted start case=no
      { "<leader>c", group = "Code Actions" },
      { "<leader>d", group = "Debug & Diagnostics" },
      { "<leader>f", group = "Find" },
      { "<leader>g", group = "Git & Goto" },
      { "<leader>gh", group = "Git Hunk" },
      { "<leader>j", group = "Jupyter" },
      { "<leader>L", group = "Language" },
      { "<leader>l", group = "LSP" },
      { "<leader>Lp", group = "Python" },
      { "<leader>o", group = "Notes" },
      { "<leader>u", group = "UI" },
      { "<leader>w", group = "Windows & Buffers" },
      { "z", group = "Code Folding" },
      -- keep-sorted end
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
