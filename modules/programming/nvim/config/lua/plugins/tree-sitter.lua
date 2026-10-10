return {
  {
    "arborist-ts/arborist.nvim",
    event = "VeryLazy",
    config = function()
      require("arborist").setup({
        ensure_installed = {
          "bash",
          "c",
          "cpp",
          "julia",
          "lua",
          "markdown",
          "markdown_inline",
          "nix",
          "python",
          "typst",
          "typescript",
        },
      })

      -- vim.api.nvim_create_autocmd("FileType", {
      --   group = vim.api.nvim_create_augroup("treesitter.setup", { clear = true }),
      --   callback = function(args)
      --     local buf = args.buf
      --     local filetype = args.match
      --     if
      --       vim.tbl_contains({
      --         "csv",
      --         "tsv",
      --         "csv_semicolon",
      --         "csv_whitespace",
      --         "csv_pipe",
      --         "rfc_csv",
      --         "rfc_semicolon",
      --       }, filetype)
      --     then
      --       return
      --     end
      --
      --     local language = vim.treesitter.language.get_lang(filetype) or filetype
      --     if not vim.treesitter.language.add(language) then
      --       return
      --     end
      --
      --     vim.treesitter.start(buf, language)
      --   end,
      -- })

      vim.keymap.set("n", "<CR>", function()
        if vim.bo.buftype ~= "" then
          vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<CR>", true, false, true), "n", false)
          return
        end
        vim.cmd("normal! v")
        vim.treesitter.select("parent")
      end, { desc = "Treesitter: start selection at node" })
      vim.keymap.set("v", "<M-Space>", function()
        vim.treesitter.select("parent")
      end, { desc = "Treesitter: expand to parent node" })
      vim.keymap.set({ "n", "v" }, "<BS>", function()
        vim.treesitter.select("child")
      end, { desc = "Treesitter: shrink to child node" })
    end,
  },
}
