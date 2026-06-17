return {
  "ThePrimeagen/refactoring.nvim",
  dependencies = {
    "lewis6991/async.nvim",
  },
  lazy = false,
  opts = {},
  keys = {
    { "<leader>ri", function() require("refactoring").refactor("Inline Variable") end, mode = { "n", "v" }, desc = "Refactor: Inline Variable" },
    { "<leader>rI", function() require("refactoring").refactor("Inline Function") end, mode = "n", desc = "Refactor: Inline Function" },
    { "<leader>rb", function() require("refactoring").refactor("Extract Block") end, mode = "n", desc = "Refactor: Extract Block" },
    { "<leader>rf", function() require("refactoring").refactor("Extract Function") end, mode = "v", desc = "Refactor: Extract Function" },
    { "<leader>rp", function() require("refactoring").refactor("Extract Parameter") end, mode = "v", desc = "Refactor: Extract Parameter" },
    { "<leader>rr", function() require("refactoring").refactor("Rename") end, mode = { "n", "v" }, desc = "Refactor: Rename" },
    { "<leader>rx", function() require("refactoring").debug.printf() end, mode = "n", desc = "Refactor: Debug Print" },
  },
}
