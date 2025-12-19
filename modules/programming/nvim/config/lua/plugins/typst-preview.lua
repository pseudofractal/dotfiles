return {
  "chomosuke/typst-preview.nvim",
  ft = "typst",
  version = "1.*",
  opts = {
    invert_colors = "never",
    open_cmd = "chromium --app=%s P typst-preview --class typst-preview",
    port = 4269,
    get_root = function(path_of_main_file)
      local bufnr = vim.fn.bufnr(path_of_main_file)
      return vim.fs.root(bufnr, { ".git" }) or vim.fn.fnamemodify(path_of_main_file, ":p:h")
    end,
  },
  keys = {
    {
      "<leader>np",
      "<cmd>TypstPreviewToggle<cr>",
      desc = "Toggle web typst preview.",
    },
  },
}
