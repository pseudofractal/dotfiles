return {
  "nvim-treesitter/nvim-treesitter-textobjects",
  dependencies = { "nvim-treesitter/nvim-treesitter" },
  init = function()
    local config = require("nvim-treesitter.configs")
    config.setup({
      textobjects = {
        select = {
          enable = true,
          lookahead = true,
          keymaps = {
            ["af"] = { query = "@function.outer", desc = "Select outer part of a function region" },
            ["if"] = { query = "@function.inner", desc = "Select inner part of a function region" },
            ["aC"] = { query = "@class.outer", desc = "Select outer part of a class region" },
            ["iC"] = { query = "@class.inner", desc = "Select inner part of a class region" },
            ["as"] = { query = "@local.scope", query_group = "locals", desc = "Select language scope" },
            ["a/"] = { query = "@comment.outer", desc = "Select outer part of a comment region" },
            ["i/"] = { query = "@comment.inner", desc = "Select outer part of a comment region" },
            ["ol"] = { query = "@loop.outer", desc = "Select outer part of a loop region" },
            ["il"] = { query = "@loop.inner", desc = "Select inner part of a loop region" },
            ["oc"] = { query = "@conditional.outer", desc = "Select outer part of a conditional region" },
            ["ic"] = { query = "@conditional.inner", desc = "Select inner part of a conditional region" },
          },
          selection_modes = {
            ["@parameter.outer"] = "v", -- charwise
            ["@function.outer"] = "V", -- linewise
            ["@class.outer"] = "<c-v>", -- blockwise
          },
          include_surrounding_whitespace = true,
        },
        swap = {
          enable = true,
          swap_next = {
            ["<leader>sa"] = { query = "@parameter.inner", desc = "Swap with the next parameter" },
          },
          swap_previous = {
            ["<leader>sA"] = { query = "@parameter.inner", desc = "Swap with the previous parameter" },
          },
        },
      },
    })
  end,
}
