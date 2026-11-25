local M = {}
local identifier = "[%w_\128-\255]"

local function import_list(line)
  local column, keyword, imports = line:match("^%s*()(%a+)%s+(.*)$")
  if keyword == "using" or keyword == "import" then
    return column, imports
  end
end

local function parent_module(node)
  while node do
    if node:type() == "module_definition" or node:type() == "source_file" then
      return node
    end
    node = node:parent()
  end
end

local function import_at_cursor(ctx)
  local row, col = unpack(ctx.cursor)
  local prefix = ctx.line:sub(1, col)
  if prefix:find("#", 1, true) then
    return
  end
  local column, imports = import_list(prefix)
  while not imports and row > 1 do
    row = row - 1
    local previous = vim.api.nvim_buf_get_lines(ctx.bufnr, row - 1, row, false)[1]:gsub("#.*$", "")
    if not previous:match("[,:]%s*$") then
      break
    end
    prefix = previous .. " " .. prefix
    column, imports = import_list(prefix)
  end
  return imports, row, column
end

local function classify(imports)
  local qualifier, members = imports:match("^%s*([%w_%.\128-\255]+)%s*:(.*)$")
  if qualifier then
    local member = vim.trim(members:match("([^,]*)$"))
    if member ~= "" and members:match("%s$") then
      return
    end
    if member:match("^@?" .. identifier .. "[%w_!\128-\255]*$") or member == "" or member == "@" then
      return { kind = "members", qualifier = qualifier, prefix = member }
    end
    return
  end
  if imports:find(":", 1, true) then
    return
  end

  local slot = vim.trim(imports:match("([^,]*)$"))
  -- A complete name followed by whitespace is waiting for a comma or colon.
  if slot ~= "" and imports:match("%s$") then
    return
  end
  if slot:match("^" .. identifier .. "*$") then
    return { kind = "package", prefix = slot }
  end
  local dots, path = slot:match("^(%.+)([%w_%.\128-\255]*)$")
  if dots then
    local module_path, partial = path:match("^(.*)%.([^.]*)$")
    return {
      kind = "relative",
      qualifier = dots .. (module_path or ""),
      prefix = partial or path,
    }
  end
end

function M.context(ctx)
  ctx = ctx
    or {
      bufnr = vim.api.nvim_get_current_buf(),
      cursor = vim.api.nvim_win_get_cursor(0),
      line = vim.api.nvim_get_current_line(),
    }
  local imports, row, column = import_at_cursor(ctx)
  local mode = imports and classify(imports)
  if not mode then
    return
  end

  local parser = vim.treesitter.get_parser(ctx.bufnr, "julia")
  if not parser then
    return mode.kind == "package" and mode or nil
  end
  local tree = parser:parse({ row - 1, row })[1]
  if not tree then
    return
  end
  local root = tree:root()
  mode.source = ctx.bufnr
  if mode.prefix == "" and mode.qualifier and vim.startswith(mode.qualifier, ".") and root:has_error() then
    -- An unfinished dot can consume a following `end` and hide the enclosing module.
    local lines = vim.api.nvim_buf_get_lines(ctx.bufnr, 0, -1, false)
    local line, col = lines[ctx.cursor[1]], ctx.cursor[2]
    lines[ctx.cursor[1]] = line:sub(1, col) .. "CompletionPlaceholder" .. line:sub(col + 1)
    mode.source = table.concat(lines, "\n")
    local recovered = vim.treesitter.get_string_parser(mode.source, "julia"):parse()[1]
    root = recovered and recovered:root() or root
  end
  local token = root:descendant_for_range(row - 1, column - 1, row - 1, column)
  if not token or (token:type() ~= "using" and token:type() ~= "import") then
    return
  end
  mode.scope = parent_module(token)
  return mode
end

function M.module_body(module)
  if module:type() == "source_file" then
    return module
  end
  for child in module:iter_children() do
    if child:type() == "block" then
      return child
    end
  end
end

local function submodules(module, text)
  local modules = {}
  local container = M.module_body(module)
  if container then
    for child in container:iter_children() do
      if child:type() == "module_definition" then
        local name = child:field("name")[1]
        if name then
          modules[vim.treesitter.get_node_text(name, text)] = child
        end
      end
    end
  end
  return modules
end

function M.resolve_module(scope, path, text)
  local dots, names = path:match("^(%.+)(.*)$")
  if dots then
    for _ = 2, #dots do
      scope = scope and parent_module(scope:parent())
    end
  else
    names = path
  end
  for name in names:gmatch("[^.]+") do
    scope = scope and submodules(scope, text)[name]
  end
  return scope
end

function M.local_modules(scope, qualifier, bufnr)
  local target = M.resolve_module(scope, qualifier, bufnr)
  return target and vim.tbl_keys(submodules(target, bufnr)) or {}
end

return M
