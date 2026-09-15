return {
  "folke/snacks.nvim",
  priority = 1000,
  lazy = false,
  opts = {
    dashboard = { enabled = true },
    input = {
      enabled = true,
      win = {
        style = "input",
        b = { completion = true },
      },
    },
    picker = {
      enabled = true,
      ui_select = true,
    },
    scroll = {
      enabled = true,
      animate = {
        duration = { step = 10, total = 100 },
      },
      animate_repeat = {
        duration = { step = 5, total = 50 },
      },
    },
    statuscolumn = {
      enabled = true,
      left = { "sign" },
      right = {},
    },
    indent = {
      enabled = true,
      scope = { enabled = false },
      hl = {
        "SnacksIndent1",
        "SnacksIndent2",
        "SnacksIndent3",
        "SnacksIndent4",
        "SnacksIndent5",
        "SnacksIndent6",
        "SnacksIndent7",
        "SnacksIndent8",
        "SnacksIndent9",
        "SnacksIndent10",
      },
    },
    words = { enabled = true },
  },
  keys = {
    {
      "<leader>F",
      function()
        Snacks.picker.smart()
      end,
      desc = "All fuzzy finders",
    },
    {
      "<leader>fr",
      function()
        Snacks.picker.resume()
      end,
      desc = "Resume old search",
    },
    {
      "<leader>ff",
      function()
        Snacks.picker.files()
      end,
      desc = "Find files in project",
    },
    {
      "<leader>fo",
      function()
        Snacks.picker.recent()
      end,
      desc = "Find recently opened files",
    },
    {
      "<leader>fF",
      function()
        Snacks.picker.files({ cwd = "~/" })
      end,
      desc = "Find file in entire system",
    },
    {
      "<leader>fG",
      function()
        Snacks.picker.files({ cwd = "~/GitHub/" })
      end,
      desc = "Find file in GitHub projects",
    },
    {
      "<leader>fC",
      function()
        Snacks.picker.files({ cwd = "~/.config/" })
      end,
      desc = "Find file in .config directory",
    },
    {
      "<leader>fc",
      function()
        Snacks.picker.files({ cwd = "~/.config/nvim/" })
      end,
      desc = "Find file in Neovim config directory",
    },
    {
      "<leader>fh",
      function()
        Snacks.picker.help()
      end,
      desc = "Find help",
    },
    {
      "<leader>fk",
      function()
        Snacks.picker.keymaps()
      end,
      desc = "Find keymaps",
    },
    {
      "<leader>/",
      function()
        Snacks.picker.grep_buffers()
      end,
      desc = "Grep current buffer",
    },
    {
      "<leader>fg",
      function()
        Snacks.picker.grep()
      end,
      desc = "Find by grep-ing in project",
    },
    {
      "<leader>gb",
      function()
        Snacks.picker.git_branches()
      end,
      desc = "Git branches",
    },
    { "<leader>n", "<cmd>Noice<cr>", desc = "Notification history" },
    {
      "<leader>st",
      function()
        Snacks.terminal()
      end,
      desc = "Toggle terminal",
    },
  },
}
