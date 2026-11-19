return {
  "MagicDuck/grug-far.nvim",
  cmd = { "GrugFar", "GrugFarWithin" },
  keys = {
    {
      "<leader>fr",
      function()
        require("grug-far").open()
      end,
      desc = "Find and replace",
    },
  },
  opts = {},
}
