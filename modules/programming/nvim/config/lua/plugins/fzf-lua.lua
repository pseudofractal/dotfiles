return {
  "ibhagwan/fzf-lua",
  dependencies = { "echasnovski/mini.icons" },
  opts = {
    winopts = {
      preview = {
        layout = "vertical",
      },
    },
  },
  keys = {
    {
      "<leader>F",
      function()
        require("fzf-lua").builtin()
      end,
      desc = "All fuzzy finders",
    },
    {
      "<leader>fr",
      function()
        require("fzf-lua").resume()
      end,
      desc = "Resume old search",
    },
    {
      "<leader>ff",
      function()
        require("fzf-lua").files()
      end,
      desc = "Find files in project",
    },
    {
      "<leader>fo",
      function()
        require("fzf-lua").oldfiles()
      end,
      desc = "Find recently opened files",
    },
    {
      "<leader>fF",
      function()
        require("fzf-lua").files({ cwd = "~/" })
      end,
      desc = "Find file in entire system",
    },
    {
      "<leader>fG",
      function()
        require("fzf-lua").files({ cwd = "~/GitHub/" })
      end,
      desc = "Find file in GitHub projects",
    },
    {
      "<leader>fC",
      function()
        require("fzf-lua").files({ cwd = "~/.config/" })
      end,
      desc = "Find file in .config directory",
    },
    {
      "<leader>fc",
      function()
        require("fzf-lua").files({ cwd = "~/.config/nvim/" })
      end,
      desc = "Find file in neovim config directory",
    },
    {
      "<leader>fh",
      function()
        require("fzf-lua").helptags()
      end,
      desc = "Find help",
    },
    {
      "<leader>fk",
      function()
        require("fzf-lua").keymaps()
      end,
      desc = "Find keymaps",
    },

    {
      "<leader>/",
      function()
        require("fzf-lua").lgrep_curbuf()
      end,
      desc = "Grep current buffer",
    },
    {
      "<leader>fg",
      function()
        require("fzf-lua").grep_project()
      end,
      desc = "Find by grep-ing in project",
    },

    {
      "<leader>gb",
      function()
        require("fzf-lua").git_branches()
      end,
      desc = "Git Branches",
    },
  },
}
