return {
  "stevearc/conform.nvim",
  keys = {
    {
      "<leader>cf",
      function()
        require("conform").format({ lsp_format = "fallback" })
      end,
      desc = "Format the current buffer",
    },
  },
  config = function()
    local conform = require("conform")

    local ft = {
      lua = { "stylua" },
      python = { "ruff_format", "ruff_organize_imports", "ruff_fix" },
      rust = { "rustfmt" },
      markdown = { "mdformat" },
      nix = { "alejandra" },
    }

    for _, f in ipairs({
      "javascript",
      "javascriptreact",
      "typescript",
      "typescriptreact",
      "json",
      "jsonc",
      "html",
      "css",
      "scss",
      "less",
    }) do
      ft[f] = function(bufnr)
        if conform.get_formatter_info("biome", bufnr).error then
          return { "biome" }
        end
        return { "prettierd" }
      end
    end

    conform.setup({
      formatters_by_ft = ft,
      format_on_save = {
        timeout_ms = 500,
        lsp_format = "fallback",
      },
    })
  end,
}

