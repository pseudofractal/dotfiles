return {
  "github/copilot.vim",
  cmd = "Copilot",
  event = "BufWinEnter",
  init = function()
    vim.g.copilot_no_maps = true
  end,
  -- config handled internally by copilot.vim
}
