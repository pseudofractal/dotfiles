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
      { "<leader>L", group = "Language" },
      { "<leader>l", group = "LSP" },
      { "<leader>Lj", group = "Julia" },
      { "<leader>Lm", group = "Markdown" },
      { "<leader>Lp", group = "Python" },
      { "<leader>Lr", group = "Rust" },
      { "<leader>Lt", group = "Typst" },
      { "<leader>Lw", group = "Web" },
      { "<leader>n", group = "Notebook" },
      { "<leader>t", group = "Test" },
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
