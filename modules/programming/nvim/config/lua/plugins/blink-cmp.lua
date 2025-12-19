return {
  "saghen/blink.cmp",
  dependencies = {
    "L3MON4D3/LuaSnip",
    "fang2hou/blink-copilot",
    "erooke/blink-cmp-latex",
    "MahanRahmati/blink-nerdfont.nvim",
  },
  version = "1.*",

  ---@module 'blink.cmp'
  ---@type blink.cmp.Config
  opts = {
    keymap = { preset = "super-tab" },
    signature = { enabled = true },
    completion = { documentation = { auto_show = true, window = { max_width = 200, max_height = 200 } } },
    fuzzy = { implementation = "prefer_rust", force_version },
    sources = {
      default = { "snippets", "lsp", "latex", "path", "copilot", "buffer" },
      providers = {
        copilot = {
          name = "copilot",
          module = "blink-copilot",
          score_offset = -100,
          async = true,
          opts = { max_completions = 2, max_attempts = 5 },
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
