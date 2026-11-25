local syntax = require("config.julia-import-syntax")
local node_text = vim.treesitter.get_node_text
local M = {}
local last_package

local type_labels = {
  struct_definition = "struct",
  abstract_definition = "abstract type",
  primitive_definition = "primitive type",
}

local signature_wrappers = {
  signature = true,
  type_head = true,
  typed_expression = true,
  where_expression = true,
  parametrized_type_expression = true,
  parenthesized_expression = true,
  binary_expression = true,
}

local declaration_macros = {
  ["@inline"] = true,
  ["@noinline"] = true,
  ["@propagate_inbounds"] = true,
  ["@generated"] = true,
}

local function binding_name(node, text)
  if not node then
    return
  end
  local kind = node:type()
  if kind == "identifier" or kind == "operator" or kind == "macro_identifier" then
    return node_text(node, text)
  end
  if signature_wrappers[kind] or kind == "call_expression" then
    return binding_name(node:named_child(0), text)
  end
end

local function is_method(node)
  if not node then
    return false
  end
  return node:type() == "call_expression" or (signature_wrappers[node:type()] and is_method(node:named_child(0)))
end

local function docstring(node, text)
  local kind = node:type()
  if kind ~= "string_literal" and kind ~= "prefixed_string_literal" then
    return
  end
  local literal = node_text(node, text)
  if kind == "prefixed_string_literal" then
    if not literal:match('^raw"') and not literal:match('^md"') then
      return
    end
    literal = literal:match('^%a+(".*)$')
  end
  local multiline = literal:match('^"""(.*)"""$')
  if not multiline then
    return literal:match('^"(.*)"$')
  end

  local lines = vim.split(multiline, "\n", { plain = true })
  local indent
  for i = 2, #lines do
    local line = lines[i]
    if line:find("%S") or i == #lines then
      local width = #(line:match("^%s*"))
      indent = math.min(indent or width, width)
    end
  end
  for i = 2, #lines do
    lines[i] = lines[i]:sub((indent or 0) + 1)
  end
  while lines[1] and not lines[1]:find("%S") do
    table.remove(lines, 1)
  end
  while lines[#lines] and not lines[#lines]:find("%S") do
    table.remove(lines)
  end
  return table.concat(lines, "\n")
end

local function declaration(node, text, docs, constant)
  if not node then
    return
  end
  local kind = node:type()
  local head = node:named_child(0)
  local name, category, signature
  if kind == "function_definition" or kind == "macro_definition" then
    name = binding_name(head, text)
    category = kind == "macro_definition" and "macro" or "function"
    if name then
      name = category == "macro" and "@" .. name or name
      signature = category .. " " .. node_text(head, text)
    end
  elseif kind == "assignment" then
    name = binding_name(head, text)
    category = is_method(head) and "function" or (constant and "constant" or "variable")
    signature = head and ((constant and "const " or "") .. node_text(head, text))
  elseif type_labels[kind] then
    name = binding_name(head, text)
    category = type_labels[kind]
    signature = head and (category .. " " .. node_text(head, text))
  elseif kind == "module_definition" then
    name = binding_name(node:field("name")[1], text)
    category = "module"
    signature = name and ("module " .. name)
  elseif kind == "const_statement" or kind == "global_statement" then
    return declaration(head, text, docs, constant or kind == "const_statement")
  elseif kind == "macrocall_expression" and head then
    local macro = node_text(head, text)
    local args = node:named_child(1)
    if not args then
      return
    end
    if macro == "@doc" and args:named_child_count() == 2 then
      local literal = docstring(args:named_child(0), text)
      local target = args:named_child(1)
      local resolved = declaration(target, text, literal)
      if resolved then
        return resolved
      end
      name = literal and binding_name(target, text)
      docs = literal
    elseif declaration_macros[macro] then
      return declaration(args:named_child(0), text, docs, constant)
    end
  end
  if name then
    return { name = name, category = category, signature = signature, docs = docs, line = node:start() + 1 }
  end
end

local function literal_include(node, text)
  local callee, args = node:named_child(0), node:named_child(1)
  if not callee or node_text(callee, text) ~= "include" or not args or args:named_child_count() ~= 1 then
    return
  end
  local path = node_text(args:named_child(0), text):match('^"([^"\\$\n]+)"$')
  return path and not vim.startswith(path, "/") and path or nil
end

local function record_definition(state, entry, path)
  entry.path = path
  local existing = state.definitions[entry.name]
  if not existing then
    state.definitions[entry.name] = entry
  elseif
    entry.category and (not existing.category or (existing.category == "function" and entry.category ~= "function"))
  then
    entry.docs = entry.docs or existing.docs
    state.definitions[entry.name] = entry
  elseif entry.docs and not existing.docs then
    existing.docs = entry.docs
  end
end

local function scan(container, text, path, state, include)
  if not container then
    return
  end
  local pending_doc, doc_end
  for child in container:iter_children() do
    if child:named() then
      local kind = child:type()
      if kind == "export_statement" or kind == "public_statement" then
        for i = 0, child:named_child_count() - 1 do
          local name = binding_name(child:named_child(i), text)
          if name then
            state.members[name] = true
          end
        end
      elseif kind == "call_expression" and include then
        local target = literal_include(child, text)
        if target then
          include(vim.fs.joinpath(vim.fs.dirname(path), target))
        end
      elseif kind == "compound_statement" then
        local block = child:named_child(0)
        if block and block:type() == "block" then
          scan(block, text, path, state, include)
        end
      else
        local entry = declaration(child, text, doc_end and child:start() <= doc_end + 1 and pending_doc or nil)
        if entry then
          record_definition(state, entry, path)
        end
      end
      pending_doc = docstring(child, text)
      doc_end = pending_doc and select(3, child:range()) or nil
    end
  end
end

local function results(state)
  local entries = {}
  for name in pairs(state.members) do
    entries[name] = state.definitions[name] or {}
  end
  return entries
end

function M.from_buffer(module, text, path)
  local state = { members = {}, definitions = {} }
  scan(module and syntax.module_body(module), text, path, state)
  return results(state)
end

local function file_revision(stat)
  return stat and table.concat({ stat.ino, stat.size, stat.mtime.sec, stat.mtime.nsec }, ":")
end

function M.from_package(path, qualifier)
  local entry_path = vim.uv.fs_realpath(path)
  if not entry_path then
    return {}
  end
  local key = entry_path .. ":" .. qualifier
  if last_package and last_package.key == key then
    local unchanged = true
    for file, revision in pairs(last_package.files) do
      if file_revision(vim.uv.fs_stat(file)) ~= revision then
        unchanged = false
        break
      end
    end
    if unchanged then
      return last_package.entries
    end
  end

  -- Bound the source scan for large packages and keep literal includes inside src.
  local source_dir = vim.fs.dirname(entry_path)
  local remaining_bytes, remaining_files = 3 * 1024 * 1024, 96
  local state = { members = {}, definitions = {} }
  local files = {}
  local function scan_file(candidate)
    local file = vim.uv.fs_realpath(candidate)
    if not file or not vim.startswith(file, source_dir .. "/") or files[file] or remaining_files == 0 then
      return
    end
    local stat = vim.uv.fs_stat(file)
    if not stat or stat.type ~= "file" or stat.size > remaining_bytes then
      return
    end
    local handle = io.open(file, "r")
    if not handle then
      return
    end
    local text = handle:read(stat.size)
    handle:close()
    if not text then
      return
    end
    files[file] = file_revision(stat)
    remaining_bytes = remaining_bytes - #text
    remaining_files = remaining_files - 1
    local tree = vim.treesitter.get_string_parser(text, "julia"):parse()[1]
    if not tree then
      return
    end
    local root = tree:root()
    local container = root
    if file == entry_path then
      local module = syntax.resolve_module(root, qualifier, text)
      container = module and syntax.module_body(module)
    end
    scan(container, text, file, state, scan_file)
  end

  scan_file(entry_path)
  local entries = results(state)
  if files[entry_path] then
    last_package = { key = key, files = files, entries = entries }
  end
  return entries
end

return M
