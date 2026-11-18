return {
  "nemanjamalesija/ts-expand-hover.nvim",
  ft = { "typescript", "typescriptreact" },
  opts = {
    keymaps = {
      -- <leader>L is the language group; <leader>Lw is Web. K stays the
      -- stock Neovim hover.
      hover = "<leader>Lwh",
      expand = "<C-n>",
      collapse = "<C-p>",
    },
  },
}
