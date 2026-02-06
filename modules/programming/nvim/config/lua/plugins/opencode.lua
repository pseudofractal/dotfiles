return {
  "NickvanDyke/opencode.nvim",
  dependencies = {
    { "folke/snacks.nvim", opts = { input = {}, picker = {}, terminal = {} } },
  },
  config = function()
    vim.env.KITTY_LISTEN_ON = "unix:/tmp/mykitty"
    ---@type opencode.Opts
    vim.g.opencode_opts = {
      provider = {
        enabled = "kitty",
        kitty = {
          type = "window",
          title = "Opencode AI",
          location = "vsplit",
          bias = 30,
          cwd = vim.fn.getcwd(),
        },
      },
    }

    vim.o.autoread = true

    -- [A]sk: Open prompt for a quick question
    vim.keymap.set({ "n", "x" }, "<leader>oa", function()
      require("opencode").ask("@this: ", { submit = true })
    end, { desc = "opencode: Ask" })

    -- [S]elect: Pick from the prompt library (Review, Explain, etc.)
    vim.keymap.set({ "n", "x" }, "<leader>os", function()
      require("opencode").select()
    end, { desc = "opencode: Select action" })

    -- [T]oggle: Show/Hide the AI chat window
    vim.keymap.set({ "n", "t" }, "<leader>ot", function()
      require("opencode").toggle()
    end, { desc = "opencode: Toggle window" })

    --  --- Operator Bindings ---
    -- Usage: 'goip' to send a paragraph, 'gow' for a word
    vim.keymap.set({ "n", "x" }, "go", function()
      return require("opencode").operator("@this ")
    end, { expr = true, desc = "opencode: Send motion to AI" })

    -- 'goo' to send the current line
    vim.keymap.set("n", "goo", function()
      return require("opencode").operator("@this ") .. "_"
    end, { expr = true, desc = "opencode: Send line to AI" })

    --  --- Navigation (Scrolling the AI Window) ---
    -- Using <leader> and directional keys for easier memory
    vim.keymap.set("n", "<leader>ou", function()
      require("opencode").command("session.half.page.up")
    end, { desc = "opencode: Scroll window up" })

    vim.keymap.set("n", "<leader>od", function()
      require("opencode").command("session.half.page.down")
    end, { desc = "opencode: Scroll window down" })
  end,
}
