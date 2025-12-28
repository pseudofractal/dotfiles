return {
  "nvim-treesitter/nvim-treesitter",
  build = ":TSUpdate",
  config = function()
    local configs = require("nvim-treesitter.configs")
    configs.setup({
      ensure_installed = {},
      sync_install = false,
      auto_install = false,

      highlight = {
        enable = true,
        disable = function(lang, buf)
          local disabled_langs = { csv = true, tsv = true }
          if disabled_langs[lang] then
            return true
          end

          local max_filesize = 1024 * 1024 -- 1 MB
          local filename = vim.api.nvim_buf_get_name(buf)

          local ok, stats = pcall(vim.uv.fs_stat, filename)

          if ok and stats and stats.size > max_filesize then
            return true
          end
        end,
      },

      indent = { enable = true },

      incremental_selection = {
        enable = true,
        keymaps = {
          init_selection = "<Enter>",
          node_incremental = "<Enter>",
          scope_incremental = false,
          node_decremental = "<Backspace>",
        },
      },
    })
  end,
}
