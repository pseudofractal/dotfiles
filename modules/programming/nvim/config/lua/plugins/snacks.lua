return {
  "folke/snacks.nvim",
  priority = 1000,
  lazy = false,
  opts = {
    dashboard = {
      enabled = true,
      preset = {
        header = [[
                      ░█▒█
        ██     ███░ █████░░
      ▒███████░██████████░
  ███▒███████████████████████░
       ██  ███████████████████░░█░███
              ███████████████████████
              ███░█░░███████████████████  ██
                     ░███████████████████████▒███
                         ░██████████░███████▒
                        ░░█████ ░███     ██
                         █▒█░]],
        keys = {
          { icon = " ", key = "f", desc = "Find File", action = ":lua Snacks.dashboard.pick('files')" },
          { icon = " ", key = "n", desc = "New File", action = ":enew" },
          { icon = " ", key = "g", desc = "Find Text", action = ":lua Snacks.dashboard.pick('live_grep')" },
          { icon = " ", key = "r", desc = "Recent Files", action = ":lua Snacks.dashboard.pick('oldfiles')" },
          {
            icon = " ",
            key = "c",
            desc = "Config",
            action = ":lua Snacks.dashboard.pick('files', {cwd = vim.fn.stdpath('config')})",
          },
          { icon = " ", key = "q", desc = "Quit", action = ":qa" },
        },
      },
      sections = {
        { section = "header" },
        { section = "keys", gap = 1, padding = 1 },
        { section = "startup" },
      },
    },
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
      "<leader>fa",
      function()
        Snacks.picker.smart()
      end,
      desc = "All fuzzy finders",
    },
    {
      "<leader>fl",
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
      "<leader>fb",
      function()
        Snacks.picker.grep_buffers()
      end,
      desc = "Search current buffer",
    },
    {
      "<leader>fg",
      function()
        Snacks.picker.grep()
      end,
      desc = "Search project with grep",
    },
    {
      "<leader>gb",
      function()
        Snacks.picker.git_branches()
      end,
      desc = "Git branches",
    },
    { "<leader>un", "<cmd>Noice<cr>", desc = "Notification history" },
    {
      "<leader>wt",
      function()
        Snacks.terminal()
      end,
      desc = "Toggle terminal",
    },
  },
}
