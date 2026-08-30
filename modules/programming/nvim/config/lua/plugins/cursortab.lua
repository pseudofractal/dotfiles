if vim.env.LLAMA_LOCAL_ENABLE ~= "1" then
  return {}
end

return {
  "leonardcser/cursortab.nvim",
  lazy = false,
  build = "cd server && go build",
  config = function(_, opts)
    require("cursortab").setup(opts)
    vim.keymap.set("n", "<Tab>", function()
      local ok, cursortab = pcall(require, "cursortab")
      if ok and cursortab.accept() then
        return ""
      end
      return vim.api.nvim_replace_termcodes("<Tab>", true, false, true)
    end, { expr = true, noremap = true, silent = true })
  end,
  opts = {
    keymaps = {
      accept = false,
      partial_accept = false,
    },
    provider = {
      type = "mercuryapi",
      api_key_env = "MERCURY_AI_TOKEN",
      model = "mercury-edit-2",
      completion_timeout = 10000,
      context_size = 0,
      max_tokens = 64,
      max_diff_history_tokens = 256,
      temperature = 0.1,
    },
    behavior = {
      enabled_modes = { "insert", "normal" },
      text_change_debounce = 500,
      idle_completion_delay = -1,
    },
    blink = {
      enabled = true,
      ghost_text = true,
    },
  },
}
