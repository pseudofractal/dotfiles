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
      ["<C-space>"] = { "show", "show_documentation", "hide_documentation" },
      ["<Tab>"] = {
        function(cmp)
          if cmp.is_ghost_text_visible() then
            return cmp.accept({ index = cmp.get_selected_item_idx() or 1 })
          end
          if cmp.is_menu_visible() then
            -- Inside a snippet, only accept a completion the user explicitly
            -- selected; otherwise let Tab advance to the next placeholder.
            local in_snippet = cmp.snippet_active({ direction = 1 })
            if not in_snippet or cmp.get_selected_item_idx() ~= nil then
              return cmp.accept()
            end
          end
        end,
        function()
          local luasnip = require("luasnip")
          if luasnip.jumpable(1) then
            luasnip.jump(1)
            return true
          end
        end,
        function()
          return require("sidekick").nes_jump_or_apply()
        end,
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
      ["<C-l>"] = {
        "snippet_forward",
        "fallback",
      },
      ["<CR>"] = { "fallback" },
    },
    cmdline = {
      enabled = true,
      keymap = {
        preset = "cmdline",
        ["<C-space>"] = { "show", "show_documentation", "hide_documentation" },
      },
      sources = { "buffer", "cmdline" },
      completion = { menu = { auto_show = true } },
    },
    signature = { enabled = true },
    snippets = { preset = "luasnip" },
    completion = {
      documentation = { auto_show = true, window = { max_width = 200, max_height = 200 } },
      menu = {
        auto_show = true,
        border = "rounded",
        max_height = 10,
      },
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
      default = { "lazydev", "lsp", "latex", "path", "buffer", "snippets" },
      providers = {
        buffer = {
          enabled = function()
            return vim.fn.getcmdtype() ~= ":"
          end,
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
