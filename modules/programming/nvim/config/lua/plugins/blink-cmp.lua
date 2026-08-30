local localSources = {}
if vim.env.LLAMA_LOCAL_ENABLE == "1" then
  localSources = { "cursortab" }
end

return {
  "saghen/blink.cmp",
  dependencies = {
    "L3MON4D3/LuaSnip",
    "erooke/blink-cmp-latex",
    "MahanRahmati/blink-nerdfont.nvim",
  },
  version = "1.*",

  ---@module 'blink.cmp'
  ---@type blink.cmp.Config
  opts = {
    keymap = {
      preset = "super-tab",
      ["<Tab>"] = {
        function(cmp)
          local ok, cursortab = pcall(require, "cursortab")
          if ok and cursortab.accept() then
            return true
          end
          if cmp.is_ghost_text_visible() then
            return cmp.accept({ index = cmp.get_selected_item_idx() or 1 })
          end
          if cmp.is_menu_visible() then
            return cmp.accept()
          end
        end,
        "snippet_forward",
        "fallback",
      },
      ["<Down>"] = {
        function(cmp)
          return cmp.select_next({ auto_insert = false, on_ghost_text = true })
        end,
        "fallback",
      },
      ["<Up>"] = {
        function(cmp)
          return cmp.select_prev({ auto_insert = false, on_ghost_text = true })
        end,
        "fallback",
      },
      ["<Right>"] = {
        function(cmp)
          return cmp.select_next({ auto_insert = false, on_ghost_text = true })
        end,
        "fallback",
      },
      ["<Left>"] = {
        function(cmp)
          return cmp.select_prev({ auto_insert = false, on_ghost_text = true })
        end,
        "fallback",
      },
      ["<S-Right>"] = {
        function(cmp)
          return cmp.select_next({ auto_insert = false, on_ghost_text = true })
        end,
        "fallback",
      },
      ["<C-l>"] = {
        "snippet_forward",
        "fallback",
      },
      ["<CR>"] = { "fallback" },
    },
    signature = { enabled = true },
    completion = {
      documentation = { auto_show = true, window = { max_width = 200, max_height = 200 } },
      list = {
        selection = {
          preselect = false,
          auto_insert = false,
        },
        cycle = {
          from_bottom = true,
          from_top = true,
        },
      },
    },
    fuzzy = { implementation = "prefer_rust" },
    sources = {
      default = vim.list_extend(
        vim.list_extend({ "lazydev", "lsp", "latex", "path" }, localSources),
        { "buffer", "snippets" }
      ),
      providers = {
        cursortab = {
          name = "CursorTab",
          module = "cursortab.blink",
          async = true,
          timeout_ms = 5000,
          score_offset = 50,
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
