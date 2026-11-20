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

-- Descriptions for blink's completion menu. LuaSnip normalises `dscr` to a line
-- table, so `snip` can fill it from this table and keep the bodies terse.
local descriptions = {
  -- math helpers
  sq = "square root",
  sum = "sum with limits",
  int = "integral with limits",
  lim = "limit",
  mat = "matrix",
  cases = "piecewise cases",
  abs = "absolute value",
  norm = "norm",
  vec = "column vector",
  cal = "calligraphic letter",
  -- tensors
  tns = "mixed tensor",
  gdn = "metric",
  gup = "inverse metric",
  chris = "Christoffel symbol",
  riem = "Riemann tensor",
  ric = "Ricci tensor",
  ein = "Einstein tensor",
  sem = "stress-energy tensor",
  pert = "metric perturbation",
  cov = "covariant derivative",
  dal = "d'Alembertian",
  eval = "evaluated boundary",
  taylor = "Taylor term",
  tr = "trace",
  -- special functions
  ylm = "spherical harmonic",
  sylm = "spin-weighted spherical harmonic",
  bess = "Bessel J",
  neum = "Neumann Y",
  hank = "Hankel H1",
  hank2 = "Hankel H2",
  ibess = "modified Bessel I",
  kbess = "modified Bessel K",
  sbess = "spherical Bessel j",
  sneum = "spherical Neumann y",
  shank = "spherical Hankel h1",
  shank2 = "spherical Hankel h2",
  leg = "associated Legendre",
  lag = "generalized Laguerre",
  herm = "Hermite",
  cheb = "Chebyshev T",
  airy = "Airy Ai",
  erf = "error function",
  zeta = "Riemann zeta",
  -- machine learning
  loss = "loss function",
  expect = "expectation",
  kl = "KL divergence",
  gauss = "Gaussian",
  attn = "attention",
  bayes = "Bayes rule",
  -- modified gravity
  conformal = "conformal metric",
  scalar = "scalar-field Lagrangian",
  gb = "Gauss-Bonnet",
  -- numerical relativity
  adm = "ADM line element",
  psi4 = "Psi_4",
  constraints = "Hamiltonian and momentum constraints",
  -- astrophysics
  kepler = "Kepler's third law",
  chirp = "chirp mass",
  hubble = "Hubble constant",
  -- document structure
  fig = "Typst figure",
  tbl = "Typst table",
  eq = "labeled equation",
  pkg = "package import",
  -- selection wrapping
  wrapb = "bold selection",
  wrapi = "italic selection",
  wrapl = "link selection",
}

local function snip(opts, nodes)
  local description = descriptions[opts.trig]
  if description then
    opts.dscr = description
  end
  return s(opts, nodes)
end

-- Text stored by `gs` in visual mode, used by the wrapping snippets.
local function selected()
  return f(function(_, snip)
    return table.concat(snip.env.LS_SELECT_RAW or {}, "\n")
  end)
end

-- Expanded as soon as the trigger is typed.
local autosnippets = {
  -- Inline math: mk -> $…$
  snip({ trig = "mk", wordTrig = true, condition = outside_math }, {
    t("$"),
    i(1),
    t("$"),
  }),

  -- Display math: dm -> $ … $ on its own lines.
  snip(
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
  snip({ trig = "^", wordTrig = false, condition = inside_math }, {
    t("^("),
    i(1),
    t(")"),
    i(0),
  }),
  snip({ trig = "_", wordTrig = false, condition = inside_math }, {
    t("_("),
    i(1),
    t(")"),
    i(0),
  }),

  -- Inline fraction: a/ -> a"/"b, so one-liners don't grow a stacked fraction.
  snip({ trig = "([^%s]+)/", regTrig = true, wordTrig = false, condition = inline_math }, {
    capture(1),
    t('"/"'),
    i(1),
    i(0),
  }),

  -- Display fraction: a/ -> (a)/(…)
  snip({
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
  snip({ trig = "dd", wordTrig = true, condition = inside_math }, {
    t("dd("),
    i(1),
    t(")"),
    i(0),
  }),

  -- Call shorthand: f..x -> f(x)
  snip({ trig = "(%S+)%s*%.%.%s*(%S+)", regTrig = true, wordTrig = false }, {
    capture(1),
    t("("),
    capture(2),
    i(1),
    t(")"),
    i(0),
  }),

  -- Alignment point in equations.
  snip({ trig = "==", wordTrig = true, condition = inside_math }, {
    t("&="),
    i(0),
  }),

  -- Lagrangian and bold vector, matching the old file.
  snip({ trig = "lll", wordTrig = true, condition = inside_math }, {
    t("cal(L)"),
    i(0),
  }),
  snip({ trig = "vv", wordTrig = true, condition = inside_math }, {
    t("vb("),
    i(1),
    t(")"),
    i(0),
  }),
}

-- Expanded on demand with Tab, so they never surprise you mid-word.
local snippets = {
  snip({ trig = "sq", wordTrig = true, condition = inside_math }, {
    t("sqrt("),
    i(1),
    t(")"),
    i(0),
  }),
  snip({ trig = "sum", wordTrig = true, condition = inside_math }, {
    t("sum_("),
    i(1, "i=1"),
    t(")^("),
    i(2, "n"),
    t(") "),
    i(0),
  }),
  snip({ trig = "int", wordTrig = true, condition = inside_math }, {
    t("integral_("),
    i(1, "a"),
    t(")^("),
    i(2, "b"),
    t(") "),
    i(0),
  }),
  snip({ trig = "lim", wordTrig = true, condition = inside_math }, {
    t("lim_("),
    i(1, "x -> oo"),
    t(") "),
    i(0),
  }),
  snip(
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
  snip(
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
  snip({ trig = "abs", wordTrig = true, condition = inside_math }, {
    t("abs("),
    i(1),
    t(")"),
    i(0),
  }),
  snip({ trig = "norm", wordTrig = true, condition = inside_math }, {
    t("norm("),
    i(1),
    t(")"),
    i(0),
  }),
  snip({ trig = "vec", wordTrig = true, condition = inside_math }, {
    t("vec("),
    i(1),
    t(")"),
    i(0),
  }),
  snip({ trig = "cal", wordTrig = true, condition = inside_math }, {
    t("cal("),
    i(1),
    t(")"),
    i(0),
  }),

  -- Tensors (physica). A `+` prefix is an upper index, `-` a lower one.
  snip({ trig = "tns", wordTrig = true, condition = inside_math }, {
    t("tensor("),
    i(1, "T"),
    t(", +"),
    i(2, "mu"),
    t(", -"),
    i(3, "nu"),
    t(")"),
    i(0),
  }),
  snip({ trig = "gdn", wordTrig = true, condition = inside_math }, {
    t("tensor(g, -"),
    i(1, "mu"),
    t(", -"),
    i(2, "nu"),
    t(")"),
    i(0),
  }),
  snip({ trig = "gup", wordTrig = true, condition = inside_math }, {
    t("tensor(g, +"),
    i(1, "mu"),
    t(", +"),
    i(2, "nu"),
    t(")"),
    i(0),
  }),
  snip({ trig = "chris", wordTrig = true, condition = inside_math }, {
    t("tensor(Gamma, +"),
    i(1, "rho"),
    t(", -"),
    i(2, "mu"),
    t(", -"),
    i(3, "nu"),
    t(")"),
    i(0),
  }),
  snip({ trig = "riem", wordTrig = true, condition = inside_math }, {
    t("tensor(R, +"),
    i(1, "rho"),
    t(", -"),
    i(2, "sigma"),
    t(", -"),
    i(3, "mu"),
    t(", -"),
    i(4, "nu"),
    t(")"),
    i(0),
  }),
  snip({ trig = "ric", wordTrig = true, condition = inside_math }, {
    t("tensor(R, -"),
    i(1, "mu"),
    t(", -"),
    i(2, "nu"),
    t(")"),
    i(0),
  }),
  snip({ trig = "ein", wordTrig = true, condition = inside_math }, {
    t("tensor(G, -"),
    i(1, "mu"),
    t(", -"),
    i(2, "nu"),
    t(")"),
    i(0),
  }),
  snip({ trig = "sem", wordTrig = true, condition = inside_math }, {
    t("tensor(T, -"),
    i(1, "mu"),
    t(", -"),
    i(2, "nu"),
    t(")"),
    i(0),
  }),
  snip({ trig = "pert", wordTrig = true, condition = inside_math }, {
    t("tensor(h, +"),
    i(1, "mu"),
    t(", +"),
    i(2, "nu"),
    t(")"),
    i(0),
  }),

  -- Derivatives and operators (physica).
  snip({ trig = "cov", wordTrig = true, condition = inside_math }, {
    t("grad_"),
    i(1, "mu"),
    t(" "),
    i(0),
  }),
  snip({ trig = "dal", wordTrig = true, condition = inside_math }, {
    t("square "),
    i(0),
  }),
  snip({ trig = "eval", wordTrig = true, condition = inside_math }, {
    t("evaluated("),
    i(1),
    t(")_("),
    i(2, "0"),
    t(")^("),
    i(3, "oo"),
    t(")"),
    i(0),
  }),
  snip({ trig = "taylor", wordTrig = true, condition = inside_math }, {
    t("taylorterm("),
    i(1, "f"),
    t(", "),
    i(2, "x"),
    t(", "),
    i(3, "x_0"),
    t(", "),
    i(4, "n"),
    t(")"),
    i(0),
  }),
  snip({ trig = "tr", wordTrig = true, condition = inside_math }, {
    t("trace("),
    i(1),
    t(")"),
    i(0),
  }),

  -- Special functions. The space before the argument parentheses keeps the
  -- arguments out of the subscript.
  snip({ trig = "ylm", wordTrig = true, condition = inside_math }, {
    t("Y_"),
    i(1, "l"),
    t("^"),
    i(2, "m"),
    t(" ("),
    i(3, "theta"),
    t(", "),
    i(4, "phi"),
    t(")"),
    i(0),
  }),
  snip({ trig = "sylm", wordTrig = true, condition = inside_math }, {
    t("attach(Y, tl: "),
    i(1, "s"),
    t(", bl: "),
    i(2, "l"),
    t(", tr: "),
    i(3, "m"),
    t(") ("),
    i(4, "theta"),
    t(", "),
    i(5, "phi"),
    t(")"),
    i(0),
  }),
  snip({ trig = "bess", wordTrig = true, condition = inside_math }, {
    t("J_"),
    i(1, "nu"),
    t(" ("),
    i(2, "x"),
    t(")"),
    i(0),
  }),
  snip({ trig = "neum", wordTrig = true, condition = inside_math }, {
    t("Y_"),
    i(1, "nu"),
    t(" ("),
    i(2, "x"),
    t(")"),
    i(0),
  }),
  snip({ trig = "hank", wordTrig = true, condition = inside_math }, {
    t("H_"),
    i(1, "nu"),
    t("^((1)) ("),
    i(2, "x"),
    t(")"),
    i(0),
  }),
  snip({ trig = "hank2", wordTrig = true, condition = inside_math }, {
    t("H_"),
    i(1, "nu"),
    t("^((2)) ("),
    i(2, "x"),
    t(")"),
    i(0),
  }),
  snip({ trig = "ibess", wordTrig = true, condition = inside_math }, {
    t("I_"),
    i(1, "nu"),
    t(" ("),
    i(2, "x"),
    t(")"),
    i(0),
  }),
  snip({ trig = "kbess", wordTrig = true, condition = inside_math }, {
    t("K_"),
    i(1, "nu"),
    t(" ("),
    i(2, "x"),
    t(")"),
    i(0),
  }),
  snip({ trig = "sbess", wordTrig = true, condition = inside_math }, {
    t("j_"),
    i(1, "l"),
    t(" ("),
    i(2, "x"),
    t(")"),
    i(0),
  }),
  snip({ trig = "sneum", wordTrig = true, condition = inside_math }, {
    t("y_"),
    i(1, "l"),
    t(" ("),
    i(2, "x"),
    t(")"),
    i(0),
  }),
  snip({ trig = "shank", wordTrig = true, condition = inside_math }, {
    t("h_"),
    i(1, "l"),
    t("^((1)) ("),
    i(2, "x"),
    t(")"),
    i(0),
  }),
  snip({ trig = "shank2", wordTrig = true, condition = inside_math }, {
    t("h_"),
    i(1, "l"),
    t("^((2)) ("),
    i(2, "x"),
    t(")"),
    i(0),
  }),
  snip({ trig = "leg", wordTrig = true, condition = inside_math }, {
    t("P_"),
    i(1, "l"),
    t("^"),
    i(2, "m"),
    t(" ("),
    i(3, "x"),
    t(")"),
    i(0),
  }),
  snip({ trig = "lag", wordTrig = true, condition = inside_math }, {
    t("L_"),
    i(1, "n"),
    t("^(("),
    i(2, "alpha"),
    t(")) ("),
    i(3, "x"),
    t(")"),
    i(0),
  }),
  snip({ trig = "herm", wordTrig = true, condition = inside_math }, {
    t("H_"),
    i(1, "n"),
    t(" ("),
    i(2, "x"),
    t(")"),
    i(0),
  }),
  snip({ trig = "cheb", wordTrig = true, condition = inside_math }, {
    t("T_"),
    i(1, "n"),
    t(" ("),
    i(2, "x"),
    t(")"),
    i(0),
  }),
  snip({ trig = "airy", wordTrig = true, condition = inside_math }, {
    t('op("Ai") ('),
    i(1, "x"),
    t(")"),
    i(0),
  }),
  snip({ trig = "erf", wordTrig = true, condition = inside_math }, {
    t('op("erf") ('),
    i(1, "x"),
    t(")"),
    i(0),
  }),
  snip({ trig = "zeta", wordTrig = true, condition = inside_math }, {
    t('op("zeta") ('),
    i(1, "s"),
    t(")"),
    i(0),
  }),

  -- Machine learning.
  snip({ trig = "loss", wordTrig = true, condition = inside_math }, {
    t("cal(L)("),
    i(1, "theta"),
    t(")"),
    i(0),
  }),
  snip({ trig = "expect", wordTrig = true, condition = inside_math }, {
    t("bb(E)_("),
    i(1, "x ~ p"),
    t(")["),
    i(2),
    t("]"),
    i(0),
  }),
  snip({ trig = "kl", wordTrig = true, condition = inside_math }, {
    t('D_"KL" ('),
    i(1, "p"),
    t(" || "),
    i(2, "q"),
    t(")"),
    i(0),
  }),
  snip({ trig = "gauss", wordTrig = true, condition = inside_math }, {
    t("cal(N) ("),
    i(1, "mu"),
    t(", "),
    i(2, "sigma^2"),
    t(")"),
    i(0),
  }),
  snip({ trig = "attn", wordTrig = true, condition = inside_math }, {
    t('op("Attention")('),
    i(1, "Q"),
    t(", "),
    i(2, "K"),
    t(", "),
    i(3, "V"),
    t(")"),
    i(0),
  }),
  snip({ trig = "bayes", wordTrig = true, condition = inside_math }, {
    t("p("),
    i(1, "theta"),
    t(" | "),
    i(2, "cal(D)"),
    t(") prop p("),
    i(3, "cal(D)"),
    t(" | "),
    i(4, "theta"),
    t(") p("),
    i(5, "theta"),
    t(")"),
    i(0),
  }),

  -- Modified gravity.
  snip({ trig = "conformal", wordTrig = true, condition = inside_math }, {
    t("tilde(g)_("),
    i(1, "mu nu"),
    t(") = Omega^2 g_("),
    i(2, "mu nu"),
    t(")"),
    i(0),
  }),
  snip({ trig = "scalar", wordTrig = true, condition = inside_math }, {
    t("cal(L) = 1/2 partial_mu phi partial^mu phi - V(phi)"),
    i(0),
  }),
  snip({ trig = "gb", wordTrig = true, condition = inside_math }, {
    t("cal(G) = R^2 - 4 R_(mu nu) R^(mu nu) + R_(mu nu rho sigma) R^(mu nu rho sigma)"),
    i(0),
  }),

  -- Numerical relativity.
  snip({ trig = "adm", wordTrig = true, condition = inside_math }, {
    t("dif s^2 = -alpha^2 dif t^2 + gamma_(i j) (dif x^i + beta^i dif t)(dif x^j + beta^j dif t)"),
    i(0),
  }),
  snip({ trig = "psi4", wordTrig = true, condition = inside_math }, {
    t("Psi_4"),
    i(0),
  }),
  snip({ trig = "constraints", wordTrig = true, condition = inside_math }, {
    t("cal(H) = 0, quad cal(M)_i = 0"),
    i(0),
  }),

  -- Astrophysics.
  snip({ trig = "kepler", wordTrig = true, condition = inside_math }, {
    t("P^2 = (4 pi^2 a^3)/(G M)"),
    i(0),
  }),
  snip({ trig = "chirp", wordTrig = true, condition = inside_math }, {
    t("cal(M) = ((m_1 m_2)^(3/5))/((m_1 + m_2)^(1/5))"),
    i(0),
  }),
  snip({ trig = "hubble", wordTrig = true, condition = inside_math }, {
    t('H_0 = 100 thin h "km s"^(-1) "Mpc"^(-1)'),
    i(0),
  }),

  -- Document structure.
  snip(
    { trig = "fig", wordTrig = true, condition = outside_math },
    vim.list_extend(
      fmt(
        [[
#figure(
  image("{}", width: 80%),
  caption: [{}],
) <fig:{}>
]],
        { i(1, "path"), i(2, "caption"), i(3, "label") }
      ),
      { i(0) }
    )
  ),
  snip(
    { trig = "tbl", wordTrig = true, condition = outside_math },
    vim.list_extend(
      fmt(
        [[
#table(
  columns: {},
  [{}], [{}],
)
]],
        { i(1, "3"), i(2), i(3) }
      ),
      { i(0) }
    )
  ),
  snip({ trig = "eq", wordTrig = true, condition = outside_math }, {
    t("$ "),
    i(1),
    t(" $ <eq:"),
    i(2, "label"),
    t(">"),
    i(0),
  }),
  snip(
    { trig = "pkg", wordTrig = true, condition = outside_math },
    vim.list_extend(
      fmt(
        [[
#import "@preview/{}: {}": *
]],
        { i(1, "package"), i(2, "0.1.0") }
      ),
      { i(0) }
    )
  ),

  -- Wrapped selections, stored with `gs` in visual mode.
  snip({ trig = "wrapb", wordTrig = true, condition = outside_math }, {
    t("*"),
    selected(),
    t("*"),
    i(0),
  }),
  snip({ trig = "wrapi", wordTrig = true, condition = outside_math }, {
    t("_"),
    selected(),
    t("_"),
    i(0),
  }),
  snip({ trig = "wrapl", wordTrig = true, condition = outside_math }, {
    t('link("'),
    i(1, "url"),
    t('")['),
    selected(),
    t("]"),
    i(0),
  }),
}

-- from_lua expects the regular snippets first and autosnippets second.
return snippets, autosnippets
