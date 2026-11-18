return {
  "mrcjkb/rustaceanvim",
  version = "^6",
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
  config = function()
    vim.api.nvim_create_autocmd("FileType", {
      pattern = "rust",
      callback = function(event)
        local map = function(keys, command, desc)
          vim.keymap.set("n", keys, "<cmd>RustLsp " .. command .. "<cr>", {
            buffer = event.buf,
            desc = "Rust: " .. desc,
          })
        end

        map("<leader>Lra", "codeAction", "Code Action")
        map("<leader>Lrd", "debug", "Debug")
        map("<leader>Lre", "explainError", "Explain Error")
        map("<leader>Lrh", "hover actions", "Hover Actions")
        map("<leader>Lro", "openDocs", "Open Docs")
        map("<leader>Lrr", "runnables", "Runnables")
        map("<leader>Lrt", "testables", "Testables")
      end,
    })
  end,
}
