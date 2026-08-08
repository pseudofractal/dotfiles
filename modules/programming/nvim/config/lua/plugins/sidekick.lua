return {
  "folke/sidekick.nvim",
  opts = {
    nes = {
      enabled = true,
      diff = { inline = "words" },
    },
    cli = {
      picker = "snacks",
      tools = {
        claude = {},
        gemini = {},
        opencode = {},
      },
    },
  },
  keys = {
    {
      "<tab>",
      function()
        if not require("sidekick.nes").apply() then
          vim.cmd("BufferLineCycleNext")
        end
      end,
      mode = "n",
      desc = "Apply NES or next buffer",
    },
    {
      "]n",
      function()
        require("sidekick.nes").jump()
      end,
      mode = "n",
      desc = "Jump to NES",
    },
    {
      "<leader>aa",
      function()
        require("sidekick.cli").toggle()
      end,
      desc = "Sidekick Toggle CLI",
    },
    {
      "<leader>as",
      function()
        require("sidekick.cli").select()
      end,
      desc = "Sidekick Select CLI",
    },
  },
}
