return {
  "mrcjkb/rustaceanvim",
  version = "^6", -- Recommended
  -- lazy.nvim defaults to lazy=true; rustaceanvim also lazy-loads itself
  init = function()
    vim.g.rustaceanvim = {
      server = {
        default_settings = {
          ["rust-analyzer"] = {
            checkOnSave = {
              command = "clippy",
            },
          },
        },
      },
    }
  end,
}
