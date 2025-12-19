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
    strategies = {
      chat = {
        adapter = {
          name = "copilot",
          model = "gpt-5-codex",
        },
        tools = {
          opts = {
            auto_submit_errors = true,
            auto_submit_success = true,
            extensions = {
              spinner = {},
            },
          },
        },
      },
      inline = {
        adapter = {
          name = "copilot",
          model = "gpt-4.1",
        },
      },
      cmd = {
        adapter = {
          name = "copilot",
          model = "gpt-4.1",
        },
      },
    },
    extensions = {
      mcphub = {
        callback = "mcphub.extensions.codecompanion",
        opts = {
          show_result_in_chat = true,
          make_vars = true,
          make_slash_commands = true,
        },
      },
    },
  },
  keys = {
    { "<leader>ai", "<cmd>CodeCompanion<CR>", desc = "Code Companion Inline" },
    { "<leader>ac", "<cmd>CodeCompanionChat<CR>", desc = "Code Companion Chat" },
    { "<leader>aa", "<cmd>CodeCompanionActions<CR>", desc = "Code Companion Actions" },
  },
}
