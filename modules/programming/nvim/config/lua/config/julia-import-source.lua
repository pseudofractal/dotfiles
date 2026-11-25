local projects = require("config.julia-projects")
local syntax = require("config.julia-import-syntax")
local members = require("config.julia-import-members")
local source = {}
local pending_sources = {}
local kinds = vim.lsp.protocol.CompletionItemKind

local member_kinds = {
  ["function"] = kinds.Function,
  macro = kinds.Function,
  constant = kinds.Constant,
  variable = kinds.Variable,
  struct = kinds.Struct,
  ["primitive type"] = kinds.Struct,
  ["abstract type"] = kinds.Interface,
  module = kinds.Module,
}

function source.new()
  return setmetatable({}, { __index = source })
end

function source:get_trigger_characters()
  return { " ", ",", ".", ":", "@", "!" }
end

local function package_members(context, qualifier, callback)
  local julia = projects.executable()
  local package = qualifier:match("^[^.]+")
  if julia == "" or not package then
    return callback({})
  end

  local key = table.concat({ julia, context.workspace, context.env.JULIA_LOAD_PATH, package }, "\n")
  local function on_source(path)
    callback(path and members.from_package(path, qualifier) or {})
  end

  if pending_sources[key] then
    table.insert(pending_sources[key], on_source)
    return
  end
  pending_sources[key] = { on_source }
  vim.system(
    {
      julia,
      "--startup-file=no",
      "--history-file=no",
      "-e",
      'print(something(Base.find_package(only(ARGS)), ""))',
      "--",
      package,
    },
    { cwd = context.workspace, env = context.env, text = true, timeout = 4000 },
    vim.schedule_wrap(function(result)
      local waiting = pending_sources[key]
      pending_sources[key] = nil
      local path = result.code == 0 and result.stdout ~= "" and result.stdout or nil
      for _, notify in ipairs(waiting) do
        notify(path)
      end
    end)
  )
end

local function name_item(ctx, mode, name, kind, detail)
  local row, col = unpack(ctx.cursor)
  local suffix = ctx.line:sub(col + 1):match("^[%w_!\128-\255]*")
  return {
    label = name,
    kind = kind,
    detail = detail,
    textEdit = {
      newText = name,
      range = {
        start = { line = row - 1, character = col - #mode.prefix },
        ["end"] = { line = row - 1, character = col + #suffix },
      },
    },
  }
end

function source:resolve(item, callback)
  local entry = item.data
  if not entry then
    return callback(item)
  end

  local sections = {}
  if entry.signature then
    sections[#sections + 1] = "```julia\n" .. entry.signature .. "\n```"
  end
  if entry.docs and entry.docs ~= "" then
    sections[#sections + 1] = entry.docs
  end
  if entry.path and entry.path ~= "" then
    sections[#sections + 1] = ("Defined in `%s:%d`"):format(vim.fn.fnamemodify(entry.path, ":~"), entry.line)
  end
  if #sections > 0 then
    item.documentation = { kind = "markdown", value = table.concat(sections, "\n\n") }
  end
  callback(item)
end

function source:execute(ctx, item, callback, apply)
  -- Keep the function icon in the menu, but insert a bare name in an import.
  apply(ctx, vim.tbl_extend("force", item, { kind = kinds.Reference }))
  callback()
end

function source:get_completions(ctx, callback)
  local function finish(items)
    callback({
      items = items,
      is_incomplete_forward = #items == 0,
      is_incomplete_backward = #items == 0,
    })
  end

  local mode = syntax.context(ctx)
  if not mode then
    return finish({})
  end
  local function names_to_items(names, kind, detail)
    local items = {}
    for _, name in ipairs(names) do
      items[#items + 1] = name_item(ctx, mode, name, kind, detail)
    end
    finish(items)
  end

  local function member_items(entries)
    local items = {}
    for name, entry in pairs(entries) do
      local item = name_item(ctx, mode, name, member_kinds[entry.category] or kinds.Reference, mode.qualifier)
      item.labelDetails = { description = entry.category or "export/public" }
      item.data = entry
      items[#items + 1] = item
    end
    finish(items)
  end

  if mode.kind == "relative" then
    return names_to_items(syntax.local_modules(mode.scope, mode.qualifier, mode.source), kinds.Module, "Local module")
  end
  if mode.kind == "members" and vim.startswith(mode.qualifier, ".") then
    local module = syntax.resolve_module(mode.scope, mode.qualifier, mode.source)
    return member_items(members.from_buffer(module, mode.source, vim.api.nvim_buf_get_name(ctx.bufnr)))
  end

  local client = vim.lsp.get_clients({ bufnr = ctx.bufnr, name = "jetls" })[1]
  local context = projects.for_buffer(ctx.bufnr, client and client.root_dir)
  if mode.kind == "members" then
    return package_members(context, mode.qualifier, member_items)
  end

  projects.package_origins(context, function(origins)
    local items = {}
    for name, path in pairs(origins) do
      items[#items + 1] = name_item(ctx, mode, name, kinds.Module, vim.fn.fnamemodify(path, ":~"))
    end
    finish(items)
  end)
end

return source
