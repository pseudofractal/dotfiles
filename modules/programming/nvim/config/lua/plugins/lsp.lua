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
      local lsp_attach_group = vim.api.nvim_create_augroup("lsp-attach", { clear = true })

      vim.api.nvim_create_autocmd("LspAttach", {
        group = lsp_attach_group,
        callback = function(event)
          local map_lsp_key = function(keys, func, desc, mode)
            mode = mode or "n"
            vim.keymap.set(mode, keys, func, { buffer = event.buf, desc = "LSP: " .. desc })
          end

          vim.keymap.set("n", "<leader>cr", function()
            return ":IncRename " .. vim.fn.expand("<cword>")
          end, { buffer = event.buf, expr = true, desc = "LSP: Rename" })

          map_lsp_key("<leader>ca", function()
            local ok, preview = pcall(require, "actions-preview")
            if ok then
              preview.code_action()
            else
              vim.lsp.buf.code_action()
            end
          end, "Code Actions")
          map_lsp_key("<leader>gr", Snacks.picker.lsp_references, "Goto References")
          map_lsp_key("<leader>gi", Snacks.picker.lsp_implementations, "Goto Implementation")
          map_lsp_key("<leader>gd", Snacks.picker.lsp_definitions, "Goto Definition")
          map_lsp_key("<leader>gD", Snacks.picker.lsp_declarations, "Goto Declaration")
          map_lsp_key("<leader>gy", Snacks.picker.lsp_type_definitions, "Goto Type Definition")
          map_lsp_key("<leader>lw", Snacks.picker.lsp_symbols, "Document Symbols")
          map_lsp_key("<leader>lW", Snacks.picker.lsp_workspace_symbols, "Workspace Symbols")
          map_lsp_key("<leader>ll", Snacks.picker.lsp_workspace_symbols, "Live Workspace Symbols")
          map_lsp_key("<leader>li", Snacks.picker.lsp_incoming_calls, "Incoming Calls")
          map_lsp_key("<leader>lo", Snacks.picker.lsp_outgoing_calls, "Outgoing Calls")
          map_lsp_key("<leader>lf", Snacks.picker.lsp_symbols, "LSP Finder")
          map_lsp_key("<leader>ld", Snacks.picker.diagnostics_buffer, "Document Diagnostics")
          map_lsp_key("<leader>lD", Snacks.picker.diagnostics, "Workspace Diagnostics")

          local client = vim.lsp.get_client_by_id(event.data.client_id)

          if client and client:supports_method(vim.lsp.protocol.Methods.textDocument_documentHighlight, event.buf) then
            local highlight =
              vim.api.nvim_create_augroup("lsp-highlight-" .. event.buf .. "-" .. client.id, { clear = true })
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
              group = vim.api.nvim_create_augroup("lsp-detach-" .. event.buf .. "-" .. client.id, { clear = true }),
              callback = function(event2)
                vim.lsp.buf.clear_references()
                vim.api.nvim_clear_autocmds({ group = highlight, buffer = event2.buf })
              end,
            })
          end

          if client and client:supports_method(vim.lsp.protocol.Methods.textDocument_inlayHint, event.buf) then
            map_lsp_key("<leader>uh", function()
              vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled({ bufnr = event.buf }), { bufnr = event.buf })
            end, "Toggle Inlay Hints")

            if client.name == "tsc" or client.name == "ts_ls" then
              vim.lsp.inlay_hint.enable(true, { bufnr = event.buf })
            end
          end

          if client and client.name == "ruff" then
            client.server_capabilities.hoverProvider = false
          end

          if client and (client.name == "tsc" or client.name == "ts_ls") then
            map_lsp_key("<leader>Lwo", function()
              vim.lsp.buf.code_action({
                apply = true,
                context = { only = { "source.organizeImports" }, diagnostics = {} },
              })
            end, "Organize Imports")

            map_lsp_key("<leader>Lwa", function()
              local line = vim.api.nvim_win_get_cursor(0)[1] - 1
              local diagnostics = {}
              for _, diagnostic in ipairs(vim.diagnostic.get(0, { lnum = line })) do
                if diagnostic.user_data and diagnostic.user_data.lsp then
                  diagnostics[#diagnostics + 1] = diagnostic.user_data.lsp
                end
              end
              vim.lsp.buf.code_action({
                apply = true,
                context = { only = { "quickfix" }, diagnostics = diagnostics },
              })
            end, "Add Missing Import")
          end

          if client and client.name == "eslint" then
            map_lsp_key("<leader>Lwe", "<cmd>LspEslintFixAll<cr>", "ESLint Fix All")
          end

          if client and client:supports_method(vim.lsp.protocol.Methods.textDocument_codeLens, event.buf) then
            map_lsp_key("<leader>lc", vim.lsp.codelens.run, "Run CodeLens")
          end
        end,
      })

      if vim.g.vscode then
        return
      end

      --- https://github.com/joe-p/kickstart.nvim/blob/1737779829e7eac109dbb98ce4290210eb9cf973/lua/joe-p/diagnostic.lua

      ---@param bufnr integer
      local function find_window_for_buffer(bufnr)
        local current_win = vim.fn.win_getid()

        if vim.fn.winbufnr(current_win) == bufnr then
          return current_win
        end

        local win_ids = vim.fn.win_findbuf(bufnr)
        local current_tabpage = vim.fn.tabpagenr()

        for _, win_id in ipairs(win_ids) do
          if vim.fn.win_id2tabwin(win_id)[1] == current_tabpage then
            return win_id
          end
        end

        return current_win
      end

      ---@param str string
      ---@param max_width integer
      local function wrap_line_at_width(str, max_width)
        if #str <= max_width then
          return { str }
        end

        local lines = {}
        local current_line = ""

        for word in string.gmatch(str, "%S+") do
          if #current_line + #word + 1 > max_width then
            table.insert(lines, current_line)
            current_line = word
          else
            if current_line ~= "" then
              current_line = current_line .. " " .. word
            else
              current_line = word
            end
          end
        end

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

      local capabilities = require("blink.cmp").get_lsp_capabilities()

      vim.lsp.config(
        "jetls",
        vim.tbl_deep_extend("force", {}, capabilities, {
          cmd = {
            "jetls",
            "--threads=16",
            "--",
            "serve",
            "--clientProcessId",
            vim.fn.getpid(),
          },
          filetypes = { "julia" },
          root_markers = { "Project.toml", ".git" },
          init_options = {
            reuse_native_inference = true,
          },
          settings = {
            jetls = {
              full_analysis = {
                debounce = 2.0,
                auto_instantiate = false,
              },
              diagnostic = {
                enabled = true,
                all_files = true,
                allow_unused_underscore = true,
              },
              code_lens = {
                references = true,
                testrunner = true,
              },
              inlay_hint = {
                block_end = { enabled = true, min_lines = 15 },
                types = { enabled = true },
              },
            },
          },
        })
      )
      vim.lsp.enable("jetls")

      -- TypeScript 7 dropped tsserver.js, so the server depends on the project:
      -- `tsc --lsp` for TS 7 and newer, `ts_ls` (tsserver) for anything older.
      local ts_major_by_root = {}
      local function project_ts_major(root)
        if ts_major_by_root[root] == nil then
          local major = 0
          local tsc = vim.fs.joinpath(root, "node_modules", ".bin", "tsc")
          if vim.fn.executable(tsc) == 1 then
            local result = vim.system({ tsc, "--version" }, { text = true }):wait()
            local version = vim.version.parse(result.stdout or "")
            if result.code == 0 and version then
              major = version.major
            end
          end
          ts_major_by_root[root] = major
        end
        return ts_major_by_root[root]
      end

      local servers = {
        harper_ls = {
          filetypes = {
            "c",
            "cpp",
            "javascript",
            "javascriptreact",
            "julia",
            "markdown",
            "python",
            "quarto",
            "rmd",
            "rust",
            "tex",
            "text",
            "typescript",
            "typescriptreact",
            "typst",
          },
          settings = {
            ["harper-ls"] = {
              diagnosticSeverity = "hint",
              dialect = "American",
              maxFileLength = 120000,
              userDictPath = vim.fn.expand("~/dotfiles/misc/harper/dictionary.txt"),
              workspaceDictPath = ".harper-dictionary.txt",
              excludePatterns = {
                "**/node_modules/**",
                "**/vendor/**",
                "**/dist/**",
                "**/build/**",
                "**/target/**",
                "**/.git/**",
                "**/*.lock",
                "**/CHANGELOG.*",
                "**/TODO.*",
                "**/.env*",
                "**/.gitignore",
              },
              linters = {
                SpellCheck = true,
                SpelledNumbers = false,
                AnA = true,
                SentenceCapitalization = true,
                UnclosedQuotes = true,
                WrongQuotes = false,
                LongSentences = true,
                RepeatedWords = true,
                Spaces = true,
                Matcher = true,
                CorrectNumberSuffix = true,
              },
            },
          },
        },
        clangd = {},
        biome = {},
        cssls = {},
        emmet_language_server = {
          filetypes = {
            "css",
            "eruby",
            "html",
            "javascript",
            "javascriptreact",
            "less",
            "sass",
            "scss",
            "svelte",
            "typescriptreact",
            "vue",
          },
        },
        eslint = {},
        html = {},
        jsonls = {},
        svelte = {},
        tailwindcss = {
          -- lspconfig falls back to `.git` for Tailwind 4, which starts the
          -- server in every repository. Only start it where Tailwind is used.
          root_dir = function(bufnr, on_dir)
            local root = vim.fs.root(bufnr, {
              "tailwind.config.js",
              "tailwind.config.cjs",
              "tailwind.config.mjs",
              "tailwind.config.ts",
              "postcss.config.js",
              "postcss.config.cjs",
              "postcss.config.mjs",
              "postcss.config.ts",
            })
            if not root then
              root = vim.fs.root(bufnr, { ".git" })
              local package_json = root and vim.fs.joinpath(root, "package.json")
              if not package_json or vim.uv.fs_stat(package_json) == nil then
                return
              end
              local contents = table.concat(vim.fn.readfile(package_json), "\n")
              if not contents:find("tailwindcss", 1, true) then
                return
              end
            end
            on_dir(root)
          end,
        },
        tsc = {
          -- ts-expand-hover.nvim needs this to know a type can expand further.
          capabilities = { experimental = { hoverVerbosityLevel = true } },
          root_dir = function(bufnr, on_dir)
            local root = vim.fs.root(
              bufnr,
              { "package-lock.json", "yarn.lock", "pnpm-lock.yaml", "bun.lockb", "bun.lock", ".git" }
            )
            if root and project_ts_major(root) >= 7 then
              on_dir(root)
            end
          end,
        },
        ts_ls = {
          root_dir = function(bufnr, on_dir)
            local root = vim.fs.root(bufnr, { "tsconfig.json", "jsconfig.json", "package.json", ".git" })
            if root and project_ts_major(root) < 7 then
              on_dir(root)
            end
          end,
        },
        yamlls = {},
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
