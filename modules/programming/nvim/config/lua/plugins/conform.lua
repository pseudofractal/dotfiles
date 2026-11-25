return {
  "stevearc/conform.nvim",
  event = { "BufWritePre" },
  keys = {
    {
      "<leader>cf",
      function()
        local format_options = { async = true, lsp_format = "fallback" }
        if vim.bo.filetype == "lean" then
          format_options.lsp_format = "prefer"
          format_options.filter = function(client)
            return client.name == "lean-fmt"
          end
        end
        require("conform").format(format_options)
      end,
      desc = "Format the current buffer",
    },
  },
  config = function()
    local conform = require("conform")

    conform.setup({
      formatters_by_ft = {
        ["*"] = { "treefmt" },
        lean = { "treefmt" },
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
        local format_options = { lsp_format = "fallback", timeout_ms = 60000 }
        if vim.bo[bufnr].filetype == "lean" then
          format_options.lsp_format = "prefer"
          format_options.filter = function(client)
            return client.name == "lean-fmt"
          end
        end
        return format_options
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
