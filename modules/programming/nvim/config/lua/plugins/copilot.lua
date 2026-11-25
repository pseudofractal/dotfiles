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
            accept = false,
          },
        },
        nes = {
          enabled = false,
        },
      })
    end,
  },
  {
    "folke/sidekick.nvim",
    opts = {
      nes = {
        enabled = true,
        clear = { esc = false },
      },
      cli = { mux = { enabled = false } },
    },
    keys = {
      {
        "<M-l>",
        function()
          if vim.api.nvim_get_mode().mode:sub(1, 1) == "i" then
            local ok, completion = pcall(require, "blink.cmp")
            if ok and completion.is_menu_visible() then
              completion.accept({ index = completion.get_selected_item_idx() or 1 })
              return ""
            end

            local suggestion_ok, suggestion = pcall(require, "copilot.suggestion")
            if suggestion_ok and suggestion.is_visible() then
              suggestion.accept()
              return ""
            end
          end

          local nes = require("sidekick.nes")
          if nes.have() then
            nes.apply()
          end

          return ""
        end,
        mode = { "n", "i", "x" },
        expr = true,
        desc = "Accept AI suggestion or apply NES",
      },
      {
        "<leader>aa",
        function()
          require("sidekick.cli").toggle()
        end,
        desc = "Sidekick: Toggle AI CLI",
      },
      {
        "<leader>ac",
        function()
          require("sidekick.cli").toggle({ name = "copilot", focus = true })
        end,
        desc = "Sidekick: Toggle Copilot",
      },
      {
        "<leader>as",
        function()
          require("sidekick.cli").select()
        end,
        desc = "Sidekick: Select AI CLI",
      },
      {
        "<leader>at",
        function()
          require("sidekick.cli").send({ msg = "{this}" })
        end,
        mode = { "n", "x" },
        desc = "Sidekick: Send This",
      },
      {
        "<leader>af",
        function()
          require("sidekick.cli").send({ msg = "{file}" })
        end,
        desc = "Sidekick: Send File",
      },
      {
        "<leader>av",
        function()
          require("sidekick.cli").send({ msg = "{selection}" })
        end,
        mode = { "x" },
        desc = "Sidekick: Send Selection",
      },
      {
        "<leader>ap",
        function()
          require("sidekick.cli").prompt()
        end,
        mode = { "n", "x" },
        desc = "Sidekick: Select Prompt",
      },
    },
  },
}
