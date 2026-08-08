return {
  "saghen/blink.cmp",
  dependencies = {
    "L3MON4D3/LuaSnip",
    "fang2hou/blink-copilot",
    "erooke/blink-cmp-latex",
    "MahanRahmati/blink-nerdfont.nvim",
    "github/copilot.vim",
    "folke/sidekick.nvim",
  },
  version = "1.*",

  ---@module 'blink.cmp'
  ---@type blink.cmp.Config
  opts = {
    keymap = {
      preset = "super-tab",
      ["<Tab>"] = {
        function(cmp)
          if cmp.is_menu_visible() then
            return cmp.select_and_accept()
          end
          local ghost = vim.fn["copilot#GetDisplayedSuggestion"]()
          if ghost and type(ghost.text) == "string" and ghost.text ~= "" then
            return vim.fn["copilot#Accept"]()
          end
        end,
        "snippet_forward",
        function()
          return require("sidekick").nes_jump_or_apply()
        end,
        "fallback",
      },
      ["<C-l>"] = {
        function(cmp)
          local ghost = vim.fn["copilot#GetDisplayedSuggestion"]()
          if ghost and type(ghost.text) == "string" and ghost.text ~= "" then
            return vim.fn["copilot#Accept"]()
          end
        end,
        "snippet_forward",
        function()
          return require("sidekick").nes_jump_or_apply()
        end,
        "fallback",
      },
      ["<CR>"] = { "accept", "fallback" },
    },
    signature = { enabled = true },
    completion = { documentation = { auto_show = true, window = { max_width = 200, max_height = 200 } } },
    fuzzy = { implementation = "prefer_rust" },
    sources = {
      default = { "lazydev", "lsp", "latex", "path", "copilot", "buffer", "snippets" },
      providers = {
        copilot = {
          name = "copilot",
          module = "blink-copilot",
          score_offset = -100,
          async = true,
          opts = { max_completions = 2, max_attempts = 5 },
        },
        lazydev = {
          name = "LazyDev",
          module = "lazydev.integrations.blink",
          score_offset = 100,
        },
        snippets = {
          score_offset = -200,
        },
        latex = {
          name = "latex",
          module = "blink-cmp-latex",
          opts = {
            insert_command = function(ctx)
              local ft = vim.api.nvim_get_option_value("filetype", {
                scope = "local",
                buf = ctx.bufnr,
              })
              if ft == "tex" then
                return true
              end
              return false
            end,
          },
        },
      },
    },
  },
  opts_extend = { "sources.default" },
}
