return {
  "stevearc/conform.nvim",
  event = { "BufWritePre" },
  keys = {
    {
      "<leader>cf",
      function()
        require("conform").format({ async = true, lsp_format = "fallback" })
      end,
      desc = "Format the current buffer",
    },
  },
  config = function()
    local conform = require("conform")

    conform.setup({
      formatters_by_ft = {
        ["*"] = { "treefmt" },
      },
      formatters = {
        treefmt = {
          args = { "--no-cache", "$FILENAME" },
          cwd = require("conform.util").root_file({ ".git/config" }),
          require_cwd = true,
          stdin = false,
          condition = function(_, ctx)
            return vim.fn.fnamemodify(ctx.filename, ":t") ~= "secrets.yaml"
          end,
        },
      },
      notify_on_error = true,
      format_after_save = function(bufnr)
        if vim.g.disable_autoformat or vim.b[bufnr].disable_autoformat then
          return
        end
        return { lsp_format = "fallback", timeout_ms = 60000 }
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
