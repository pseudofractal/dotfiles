local ls = require("luasnip")
local s = ls.snippet
local t = ls.text_node
local i = ls.insert_node
local f = ls.function_node
local fmt = require("luasnip.extras.fmt").fmt

-- Math detection cannot rely on the syntax tree: while a formula is being
-- typed it is often incomplete (`$a/` parses as an ERROR node), and the Typst
-- grammar even reads a `$` inside a code string as the start of math.
--
-- Instead, scan up to the cursor and count unescaped `$` that are not inside a
-- raw block, string, or comment. An odd count means the cursor is inside math;
-- the character after the opening `$` tells inline from display.
local function starts_code_string(line, position)
  local before = line:sub(1, position - 1):gsub("%s+$", "")
  if before == "" then
    return false
  end
  local previous = before:sub(-1)
  -- In markup a quote usually follows a word ("he said ..."); in code it
  -- follows an operator or delimiter (`=`, `(`, `,`, ...).
  return not previous:match("[%w_]") and previous ~= '"'
end

local function math_context()
  local cursor = vim.api.nvim_win_get_cursor(0)
  local row, col = cursor[1] - 1, cursor[2]

  local count = 0
  local open_row, open_col = nil, nil

  local in_raw = false
  local raw_ticks = 0
  local in_string = false
  local in_line_comment = false
  local block_comment_depth = 0
  local escaped = false

  local lines = vim.api.nvim_buf_get_lines(0, 0, row + 1, false)
  for index, line in ipairs(lines) do
    local limit = (index - 1 == row) and col or #line
    local position = 1
    in_line_comment = false

    while position <= limit do
      local char = line:sub(position, position)
      local next_char = line:sub(position + 1, position + 1)

      if escaped then
        escaped = false
      elseif char == "\\" then
        escaped = true
      elseif block_comment_depth > 0 then
        if char == "/" and next_char == "*" then
          block_comment_depth = block_comment_depth + 1
          position = position + 1
        elseif char == "*" and next_char == "/" then
          block_comment_depth = block_comment_depth - 1
          position = position + 1
        end
      elseif in_line_comment then
        -- Skip to the end of the line.
      elseif in_raw then
        if char == "`" then
          local ticks = 1
          while line:sub(position + ticks, position + ticks) == "`" do
            ticks = ticks + 1
          end
          if ticks >= raw_ticks then
            in_raw = false
          end
          position = position + ticks - 1
        end
      elseif in_string then
        if char == '"' then
          in_string = false
        end
      elseif char == "`" then
        local ticks = 1
        while line:sub(position + ticks, position + ticks) == "`" do
          ticks = ticks + 1
        end
        in_raw = true
        raw_ticks = ticks
        position = position + ticks - 1
      elseif char == '"' and starts_code_string(line, position) then
        in_string = true
      elseif char == "/" and next_char == "/" then
        in_line_comment = true
        position = position + 1
      elseif char == "/" and next_char == "*" then
        block_comment_depth = 1
        position = position + 1
      elseif char == "$" then
        count = count + 1
        open_row, open_col = index - 1, position - 1
      end

      position = position + 1
    end

    -- A trailing backslash is a line break, not an escape for the next line.
    escaped = false
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
