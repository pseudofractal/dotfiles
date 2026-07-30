return {
  "mfussenegger/nvim-lint",
  config = function()
    require("lint").linters_by_ft = {
      markdown = { "markdownlint-cli2" },
      cpp = { "cpplint" },
      lua = { "luacheck" },
    }
    vim.api.nvim_create_autocmd({ "BufWritePost" }, {
      callback = function()
        require("lint").try_lint()
      end,
    })
  end,
}
