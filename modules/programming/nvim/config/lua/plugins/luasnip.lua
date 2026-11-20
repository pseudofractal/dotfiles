return {
  "L3MON4D3/LuaSnip",
  version = "v2.*",
  build = "make install_jsregexp",
  dependencies = { "rafamadriz/friendly-snippets" },
  config = function()
    require("luasnip").config.set_config({
      enable_autosnippets = true,
      history = true,
      updateevents = "TextChanged,TextChangedI",
      region_check_events = "CursorMoved",
      delete_check_events = "TextChanged",
      store_selection_keys = "gs",
    })

    require("luasnip.loaders.from_lua").lazy_load({
      paths = vim.fn.stdpath("config") .. "/snippets",
      default_priority = 2000,
    })
    require("luasnip.loaders.from_vscode").lazy_load({ default_priority = 1000 })
  end,
}
