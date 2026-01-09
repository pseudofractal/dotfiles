return {
  "olimorris/codecompanion.nvim",
  dependencies = {
    "nvim-lua/plenary.nvim",
    "nvim-treesitter/nvim-treesitter",
    "ravitemer/mcphub.nvim",
    {
      "MeanderingProgrammer/render-markdown.nvim",
      ft = { "markdown", "codecompanion" },
    },
    {
      "HakonHarnes/img-clip.nvim",
      opts = {
        filetypes = {
          codecompanion = {
            prompt_for_file_name = false,
            template = "[Image]($FILE_PATH)",
            use_absolute_path = true,
          },
        },
      },
    },
    {
      "echasnovski/mini.diff",
      config = function()
        local diff = require("mini.diff")
        diff.setup({
          source = diff.gen_source.none(),
        })
      end,
    },
    "franco-ruggeri/codecompanion-spinner.nvim",
    "ravitemer/codecompanion-history.nvim",
  },
  opts = {
    interactions = {
      chat = {
        adapter = "gemini_cli",
      },
      inline = {
        adapter = "copilot",
      },
    },
    adapters = {
      acp = {
        gemini_cli = function()
          return require("codecompanion.adapters").extend("gemini_cli", {
            defaults = {
              auth_method = "oauth-personal",
            },
          })
        end,
      },
    },
  },
  keys = {
    { "<leader>ai", "<cmd>CodeCompanion<CR>", desc = "Code Companion Inline" },
    { "<leader>ac", "<cmd>CodeCompanionChat<CR>", desc = "Code Companion Chat" },
    { "<leader>aa", "<cmd>CodeCompanionActions<CR>", desc = "Code Companion Actions" },
  },
}
