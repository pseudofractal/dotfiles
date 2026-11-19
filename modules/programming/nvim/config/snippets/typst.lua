local ls = require("luasnip")
local s = ls.snippet
local t = ls.text_node
local i = ls.insert_node
local f = ls.function_node
local fmt = require("luasnip.extras.fmt").fmt

-- Math detection cannot rely on the syntax tree: while a formula is being
-- typed it is often incomplete (`$a/` is an ERROR node with no `math`
-- ancestor). Typst only uses `$` as a math delimiter, so count the unescaped
-- dollars before the cursor instead. An odd count means the cursor is inside
-- math, and the character after the opening `$` distinguishes `$x$` (inline)
-- from `$ x $` and multi-line blocks (display).
local function math_context()
  local cursor = vim.api.nvim_win_get_cursor(0)
  local row, col = cursor[1] - 1, cursor[2]

  local count = 0
  local open_row, open_col = nil, nil

  local lines = vim.api.nvim_buf_get_lines(0, 0, row + 1, false)
  for index, line in ipairs(lines) do
    local limit = (index - 1 == row) and col or #line
    local position = 1
    while position <= limit do
      if line:sub(position, position) == "$" and line:sub(position - 1, position - 1) ~= "\\" then
        count = count + 1
        open_row, open_col = index - 1, position - 1
      end
      position = position + 1
    end
  end

  if count % 2 == 0 then
    return nil
  end

  local line = vim.api.nvim_buf_get_lines(0, open_row, open_row + 1, false)[1] or ""
  local next_char = line:sub(open_col + 2, open_col + 2)
  return { inline = next_char ~= "" and not next_char:match("%s") }
end

local function inside_math()
  return math_context() ~= nil
end

local function outside_math()
  return not inside_math()
end

local function inline_math()
  local context = math_context()
  return context ~= nil and context.inline
end

-- LuaSnip regex captures are 1-indexed; this keeps the regex snippets readable.
local function capture(index)
  return f(function(_, snip)
    return snip.captures[index]
  end)
end

-- Expanded as soon as the trigger is typed.
local autosnippets = {
  -- Inline math: mk -> $…$
  s({ trig = "mk", wordTrig = true, condition = outside_math }, {
    t("$"),
    i(1),
    t("$"),
  }),

  -- Display math: dm -> $ … $ on its own lines.
  s(
    { trig = "dm", wordTrig = true, condition = outside_math },
    fmt(
      [[
$
{}
$
{}
]],
      { i(1), i(0) }
    )
  ),

  -- Superscript and subscript. wordTrig must stay false: the trigger follows a
  -- letter in `x^` and `x_`, which is exactly where it should fire.
  s({ trig = "^", wordTrig = false, condition = inside_math }, {
    t("^("),
    i(1),
    t(")"),
    i(0),
  }),
  s({ trig = "_", wordTrig = false, condition = inside_math }, {
    t("_("),
    i(1),
    t(")"),
    i(0),
  }),

  -- Inline fraction: a/ -> a"/"b, so one-liners don't grow a stacked fraction.
  s({ trig = "([^%s]+)/", regTrig = true, wordTrig = false, condition = inline_math }, {
    capture(1),
    t('"/"'),
    i(1),
    i(0),
  }),

  -- Display fraction: a/ -> (a)/(…)
  s({
    trig = "([^%s%$]+)/",
    regTrig = true,
    wordTrig = false,
    condition = function()
      return inside_math() and not inline_math()
    end,
  }, {
    t("("),
    capture(1),
    t(")/("),
    i(1),
    t(")"),
    i(0),
  }),

  -- Differential, requires the physica package.
  s({ trig = "dd", wordTrig = true, condition = inside_math }, {
    t("dd("),
    i(1),
    t(")"),
    i(0),
  }),

  -- Call shorthand: f..x -> f(x)
  s({ trig = "(%S+)%s*%.%.%s*(%S+)", regTrig = true, wordTrig = false }, {
    capture(1),
    t("("),
    capture(2),
    i(1),
    t(")"),
    i(0),
  }),

  -- Alignment point in equations.
  s({ trig = "==", wordTrig = true, condition = inside_math }, {
    t("&="),
    i(0),
  }),

  -- Lagrangian and bold vector, matching the old file.
  s({ trig = "lll", wordTrig = true, condition = inside_math }, {
    t("cal(L)"),
    i(0),
  }),
  s({ trig = "vv", wordTrig = true, condition = inside_math }, {
    t("vb("),
    i(1),
    t(")"),
    i(0),
  }),
}

-- Expanded on demand with Tab, so they never surprise you mid-word.
local snippets = {
  s({ trig = "sq", wordTrig = true, condition = inside_math }, {
    t("sqrt("),
    i(1),
    t(")"),
    i(0),
  }),
  s({ trig = "sum", wordTrig = true, condition = inside_math }, {
    t("sum_("),
    i(1, "i=1"),
    t(")^("),
    i(2, "n"),
    t(") "),
    i(0),
  }),
  s({ trig = "int", wordTrig = true, condition = inside_math }, {
    t("integral_("),
    i(1, "a"),
    t(")^("),
    i(2, "b"),
    t(") "),
    i(0),
  }),
  s({ trig = "lim", wordTrig = true, condition = inside_math }, {
    t("lim_("),
    i(1, "x -> oo"),
    t(") "),
    i(0),
  }),
  s(
    { trig = "mat", wordTrig = true, condition = inside_math },
    fmt(
      [[
mat(
  {}, {};
  {}, {}
)
]],
      { i(1), i(2), i(3), i(4) }
    )
  ),
  s(
    { trig = "cases", wordTrig = true, condition = inside_math },
    fmt(
      [[
cases(
  {} & "if" {};
  {} & "otherwise"
)
]],
      { i(1), i(2), i(3) }
    )
  ),
  s({ trig = "abs", wordTrig = true, condition = inside_math }, {
    t("abs("),
    i(1),
    t(")"),
    i(0),
  }),
  s({ trig = "norm", wordTrig = true, condition = inside_math }, {
    t("norm("),
    i(1),
    t(")"),
    i(0),
  }),
  s({ trig = "vec", wordTrig = true, condition = inside_math }, {
    t("vec("),
    i(1),
    t(")"),
    i(0),
  }),
  s({ trig = "cal", wordTrig = true, condition = inside_math }, {
    t("cal("),
    i(1),
    t(")"),
    i(0),
  }),
}

-- from_lua expects the regular snippets first and autosnippets second.
return snippets, autosnippets
