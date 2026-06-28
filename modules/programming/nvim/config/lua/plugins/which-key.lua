return {
  "folke/which-key.nvim",
  event = "VeryLazy",
  opts = {
    spec = {
      { "<leader>c", group = "Code Actions" },
      { "<leader>d", group = "Debug" },
      { "<leader>f", group = "Find" },
      { "<leader>g", group = "Git" },
      { "<leader>gh", group = "Git Hunk" },
      { "<leader>j", group = "Jump" },
      { "<leader>l", group = "LSP" },
      { "<leader>m", group = "Markdown" },
      { "<leader>n", group = "Notes" },
      { "<leader>r", group = "Refactor" },
      { "<leader>s", group = "Swap" },
      { "<leader>t", group = "Toggle" },
      { "<leader>w", group = "Window" },
      { "<leader>L", group = "Language" },
      { "<leader>Lp", group = "Python" },
      { "<leader>x", group = "Diagnostics" },
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
