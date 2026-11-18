return {
  {
    "zbirenbaum/copilot.lua",
    dependencies = { "copilotlsp-nvim/copilot-lsp" },
    cmd = "Copilot",
    event = "InsertEnter",
    config = function()
      require("copilot").setup({
        suggestion = {
          enabled = true,
          auto_trigger = true,
          keymap = {
            accept = "<M-l>",
          },
        },
        nes = {
          enabled = true,
        },
      })
    end,
  },
  {
    "folke/sidekick.nvim",
    opts = {
      nes = { enabled = true },
      cli = { mux = { enabled = false } },
    },
  },
}
