return {
  "mfussenegger/nvim-lint",
  config = function()
    require("lint").linters_by_ft = {
      markdown = { "markdownlint-cli2" },
      javascript = { "biomejs" },
      typescript = { "biomejs" },
      cpp = { "cpplint" },
      python = { "ruff" },
      lua = { "luacheck" },
    }
    vim.api.nvim_create_autocmd({ "BufWritePost" }, {
      callback = function()
        require("lint").try_lint()
        -- require("lint").try_lint("cspell")
      end,
    })
  end,
}
