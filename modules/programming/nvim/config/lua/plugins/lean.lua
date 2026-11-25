return {
  {
    "Julian/lean.nvim",
    ft = { "lean" },
    init = function()
      vim.g.lean_config = {
        mappings = true,
        abbreviations = { enable = true, leader = "\\" },
        infoview = {
          autoopen = true,
          orientation = "auto",
        },
        lsp = {
          init_options = {
            editDelay = 100,
            hasWidgets = true,
          },
        },
      }
    end,
    config = function()
      vim.lsp.config("lean-fmt", {
        cmd = function(dispatchers, client_config)
          local project_root = client_config.root_dir
          local formatter =
            vim.fs.joinpath(project_root, ".lake", "packages", "lean-fmt", ".lake", "build", "bin", "lean-fmt")

          return vim.lsp.rpc.start({ formatter, "lsp" }, dispatchers, { cwd = project_root })
        end,
        filetypes = { "lean" },
        root_dir = function(bufnr, on_dir)
          local project_root = vim.fs.root(bufnr, { "lakefile.lean", "lakefile.toml" })
          if not project_root then
            return
          end

          local formatter =
            vim.fs.joinpath(project_root, ".lake", "packages", "lean-fmt", ".lake", "build", "bin", "lean-fmt")
          if vim.fn.executable(formatter) == 1 then
            on_dir(project_root)
          end
        end,
        init_options = { debounceMs = 150 },
      })
      vim.lsp.enable("lean-fmt")
    end,
  },
}
