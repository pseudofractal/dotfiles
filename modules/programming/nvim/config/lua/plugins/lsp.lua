return {
  {
    "folke/lazydev.nvim",
    ft = "lua",
    opts = {
      library = {
        { path = "${3rd}/luv/library", words = { "vim%.uv" } },
      },
    },
  },
  {
    "neovim/nvim-lspconfig",
    dependencies = {
      { "j-hui/fidget.nvim", opts = {} },
      "saghen/blink.cmp",
    },
    config = function()
      vim.api.nvim_create_autocmd("LspAttach", {
        group = vim.api.nvim_create_augroup("lsp-attach", { clear = true }),
        callback = function(event)
          local map_lsp_key = function(keys, func, desc, mode)
            mode = mode or "n"
            vim.keymap.set(mode, keys, func, { buffer = event.buf, desc = "LSP: " .. desc })
          end

          map_lsp_key("<leader>cr", vim.lsp.buf.rename, "Rename")
          map_lsp_key("<leader>ca", require("fzf-lua").lsp_code_actions, "Code Actions")
          map_lsp_key("<leader>jr", require("fzf-lua").lsp_references, "Goto References")
          map_lsp_key("<leader>ji", require("fzf-lua").lsp_implementations, "Goto Implementation")
          map_lsp_key("<leader>jd", require("fzf-lua").lsp_definitions, "Goto Definition")
          map_lsp_key("<leader>jD", require("fzf-lua").lsp_declarations, "Goto Declaration")
          map_lsp_key("<leader>jt", require("fzf-lua").lsp_typedefs, "Goto Type Definition")
          map_lsp_key("<leader>lw", require("fzf-lua").lsp_document_symbols, "Document Symbols")
          map_lsp_key("<leader>lW", require("fzf-lua").lsp_workspace_symbols, "Workspace Symbols")
          map_lsp_key("<leader>ll", require("fzf-lua").lsp_live_workspace_symbols, "Live Workspace Symbols")
          map_lsp_key("<leader>li", require("fzf-lua").lsp_incoming_calls, "Incoming Calls")
          map_lsp_key("<leader>lo", require("fzf-lua").lsp_outgoing_calls, "Outgoing Calls")
          map_lsp_key("<leader>lf", require("fzf-lua").lsp_finder, "LSP Finder")
          map_lsp_key("<leader>ld", require("fzf-lua").diagnostics_document, "Document Diagnostics")
          map_lsp_key("<leader>lD", require("fzf-lua").diagnostics_workspace, "Workspace Diagnostics")

          local client = vim.lsp.get_client_by_id(event.data.client_id)

          if client and client:supports_method(vim.lsp.protocol.Methods.textDocument_documentHighlight, event.buf) then
            local highlight = vim.api.nvim_create_augroup("lsp-highlight", { clear = true })
            vim.api.nvim_create_autocmd({ "CursorHold", "CursorHoldI" }, {
              buffer = event.buf,
              group = highlight,
              callback = vim.lsp.buf.document_highlight,
            })
            vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI" }, {
              buffer = event.buf,
              group = highlight,
              callback = vim.lsp.buf.clear_references,
            })
            vim.api.nvim_create_autocmd("LspDetach", {
              group = vim.api.nvim_create_augroup("lsp-detach", { clear = true }),
              callback = function(event2)
                vim.lsp.buf.clear_references()
                vim.api.nvim_clear_autocmds({ group = "lsp-highlight", buffer = event2.buf })
              end,
            })
          end

          if client and client:supports_method(vim.lsp.protocol.Methods.textDocument_inlayHint, event.buf) then
            map_lsp_key("<leader>th", function()
              vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled({ bufnr = event.buf }))
            end, "Toggle Inlay Hints")
          end

          if client and client.name == "ruff" then
            client.server_capabilities.hoverProvider = false
          end

          map_lsp_key("<leader>lc", vim.lsp.codelens.run, "Run CodeLens")
        end,
      })

      if vim.g.vscode then
        return
      end

      ------------------------------------------------- DIAGNOSTICS ARE WRITTEN BY GODS
      --- https://github.com/joe-p/kickstart.nvim/blob/1737779829e7eac109dbb98ce4290210eb9cf973/lua/joe-p/diagnostic.lua

      -- Get the window id for a buffer
      -- @param bufnr integer
      local function find_window_for_buffer(bufnr)
        local current_win = vim.fn.win_getid()

        -- Check if current window has the buffer
        if vim.fn.winbufnr(current_win) == bufnr then
          return current_win
        end

        -- Otherwise, find a visible window with this buffer
        local win_ids = vim.fn.win_findbuf(bufnr)
        local current_tabpage = vim.fn.tabpagenr()

        for _, win_id in ipairs(win_ids) do
          if vim.fn.win_id2tabwin(win_id)[1] == current_tabpage then
            return win_id
          end
        end

        return current_win
      end

      -- Split a string into multiple lines, each no longer than max_width
      -- The split will only occur on spaces to preserve readability
      -- @param str string
      -- @param max_width integer
      local function wrap_line_at_width(str, max_width)
        if #str <= max_width then
          return { str }
        end

        local lines = {}
        local current_line = ""

        for word in string.gmatch(str, "%S+") do
          -- If adding this word would exceed max_width
          if #current_line + #word + 1 > max_width then
            -- Add the current line to our results
            table.insert(lines, current_line)
            current_line = word
          else
            -- Add word to the current line with a space if needed
            if current_line ~= "" then
              current_line = current_line .. " " .. word
            else
              current_line = word
            end
          end
        end

        -- Don't forget the last line
        if current_line ~= "" then
          table.insert(lines, current_line)
        end

        return lines
      end

      ---@param diagnostic vim.Diagnostic
      local function format_virtual_lines(diagnostic)
        local window_id = find_window_for_buffer(diagnostic.bufnr)
        local sign_column_width = vim.fn.getwininfo(window_id)[1].textoff
        local text_area_width = vim.api.nvim_win_get_width(window_id) - sign_column_width
        local center_width = 5
        local left_width = 1

        ---@type string[]
        local lines = {}
        for msg_line in diagnostic.message:gmatch("([^\n]+)") do
          local max_width = text_area_width - diagnostic.col - center_width - left_width
          vim.list_extend(lines, wrap_line_at_width(msg_line, max_width))
        end

        return table.concat(lines, "\n")
      end

      vim.diagnostic.config({
        severity_sort = true,
        virtual_text = false,
        underline = { severity = vim.diagnostic.severity.ERROR },
        signs = vim.g.have_nerd_font and {
          text = {
            [vim.diagnostic.severity.ERROR] = "󰅚 ",
            [vim.diagnostic.severity.WARN] = "󰀪 ",
            [vim.diagnostic.severity.INFO] = "󰋽 ",
            [vim.diagnostic.severity.HINT] = "󰌶 ",
          },
        } or {},
        virtual_lines = { format = format_virtual_lines, current_line = true },
      })

      vim.api.nvim_create_autocmd({ "InsertLeave", "DiagnosticChanged" }, {
        callback = function()
          vim.diagnostic.hide()
          vim.diagnostic.show()
        end,
      })

      ----------------------------- DIAGNOSTICS OVER

      --- Code Lens
      vim.lsp.codelens.enable(true)

      vim.api.nvim_create_autocmd({
        "BufEnter",
        "CursorHold",
        "InsertLeave",
      }, {
        callback = function()
          vim.lsp.codelens.refresh()
        end,
      })

      vim.lsp.commands["editor.action.showReferences"] = function()
        require("fzf-lua").lsp_references()
      end
      -----  Code Lens

      local capabilities = require("blink.cmp").get_lsp_capabilities()

      --- Julia Language Server jetls
      vim.lsp.config("jetls", vim.tbl_deep_extend("force", {}, capabilities, {
        cmd = { "jetls", "serve" },
        filetypes = { "julia" },
        root_markers = { "Project.toml", "Manifest.toml", ".git" },
      }))
      vim.lsp.enable("jetls", false)
      vim.lsp.enable("jetls")

      local servers = {
        clangd = {},
        biome = {},
        astro = {
          filetypes = { "astro", "mdx" },
          init_options = {
            typescript = {
              tsdk = vim.fs.joinpath(vim.fn.getcwd(), "node_modules", "typescript", "lib"),
            },
          },
        },
        ruff = {
          init_options = {
            settings = {
              configurationPreference = "filesystemFirst",
            },
          },
        },
        -- julials = {
        --   filetypes = {"julia"},
        --   root_markers = { "Project.toml", "Manifest.toml", ".git" },
        -- },
        ty = {
          settings = {
            ty = {
              diagnosticMode = "workspace",
              inlayHints = {
                variableTypes = true,
                callArgumentNames = true,
              },
              completions = {
                autoImport = true,
                completeFunctionParentheses = false,
              },
              configuration = {
                analysis = {
                  ["replace-imports-with-any"] = {
                    "astropy.**",
                    "astroquery.**",
                    "photutils.**",
                    "sunpy.**",
                    "gatspy.**",
                    "sep",
                    "reproject.**",
                    "specutils.**",
                    "regions",
                    "imutils",
                    "ccdproc.**",
                    "astrometry.**",
                    "emcee",
                    "corner",
                    "petrofit.**",
                    "lenstools.**",
                    "extinction",
                    "dustapprox.**",
                    "galpy.**",
                    "pynbody.**",
                    "yt.**",
                    "pyregion.**",
                    "aplpy.**",
                  },
                },
              },
            },
          },
        },
        marksman = {},
        nixd = {},
        tinymist = {
          root_markers = { "typst.toml", ".git" },
          settings = {
            exportPdf = "onType",
          },
        },
        lua_ls = {
          settings = {
            Lua = {
              completion = { callSnippet = "Replace" },
            },
          },
        },
      }

      for server_name, server_opts in pairs(servers) do
        server_opts.capabilities = vim.tbl_deep_extend("force", {}, capabilities, server_opts.capabilities or {})
        vim.lsp.config(server_name, server_opts)
        vim.lsp.enable(server_name)
      end
    end,
  },
}
