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

    conform.setup({
      formatters_by_ft = {
        ["*"] = { "treefmt", lsp_format = "fallback" },
      },
      formatters = {
        treefmt = {
          require_cwd = false,
          cwd = function()
            return vim.fn.getcwd()
          end,
        },
      },
      format_on_save = function(bufnr)
        if vim.g.disable_autoformat or vim.b[bufnr].disable_autoformat then
          return
        end
        return { timeout_ms = 500, lsp_format = "fallback" }
      end,
    })

    vim.api.nvim_create_user_command("FormatDisable", function(args)
      if args.bang then
        vim.g.disable_autoformat = true
      else
        vim.b.disable_autoformat = true
      end
    end, {
      desc = "Disable autoformat-on-save",
      bang = true,
    })

    vim.api.nvim_create_user_command("FormatEnable", function()
      vim.b.disable_autoformat = false
      vim.g.disable_autoformat = false
    end, {
      desc = "Re-enable autoformat-on-save",
    })
  end,
}
