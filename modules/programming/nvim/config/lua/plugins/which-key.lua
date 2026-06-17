return {
  "folke/which-key.nvim",
  event = "VeryLazy",
  opts = {
    spec = {
      { "<leader>c", group = "code" },
      { "<leader>d", group = "debug" },
      { "<leader>f", group = "find" },
      { "<leader>g", group = "git" },
      { "<leader>gh", group = "hunk" },
      { "<leader>j", group = "jump" },
      { "<leader>l", group = "lsp" },
      { "<leader>m", group = "markdown" },
      { "<leader>n", group = "notes" },
      { "<leader>r", group = "refactor" },
      { "<leader>s", group = "swap" },
      { "<leader>t", group = "toggle" },
      { "<leader>w", group = "window" },
      { "<leader>x", group = "trouble" },
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
