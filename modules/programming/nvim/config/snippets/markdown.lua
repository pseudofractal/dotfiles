local ls = require("luasnip")
local s = ls.snippet
local t = ls.text_node
local i = ls.insert_node
local f = ls.function_node

-- Text stored by `gs` in visual mode.
local function selected()
  return f(function(_, snip)
    return table.concat(snip.env.LS_SELECT_RAW or {}, "\n")
  end)
end

return {
  s({ trig = "wrapb", wordTrig = true, dscr = "bold selection" }, {
    t("**"),
    selected(),
    t("**"),
    i(0),
  }),
  s({ trig = "wrapi", wordTrig = true, dscr = "italic selection" }, {
    t("*"),
    selected(),
    t("*"),
    i(0),
  }),
  s({ trig = "wrapl", wordTrig = true, dscr = "link selection" }, {
    t("["),
    selected(),
    t("]("),
    i(1, "url"),
    t(")"),
    i(0),
  }),
}
