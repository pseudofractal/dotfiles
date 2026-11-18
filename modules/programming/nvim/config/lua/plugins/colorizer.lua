return {
  "catgoose/nvim-colorizer.lua",
  event = "BufReadPre",
  opts = {
    filetypes = {
      "astro",
      "css",
      "html",
      "javascript",
      "javascriptreact",
      "scss",
      "svelte",
      "typescript",
      "typescriptreact",
      "vue",
    },
    options = {
      parsers = {
        css = true,
        tailwind = { enable = true },
      },
    },
  },
}
