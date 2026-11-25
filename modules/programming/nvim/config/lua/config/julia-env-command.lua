vim.api.nvim_create_user_command("JuliaEnv", function()
  local projects = require("config.julia-projects")
  local context = projects.for_buffer(0)
  vim.cmd("botright new")
  local buffer = vim.api.nvim_get_current_buf()
  vim.bo[buffer].buftype = "nofile"
  vim.bo[buffer].bufhidden = "wipe"
  vim.bo[buffer].swapfile = false
  vim.keymap.set("n", "q", "<cmd>close<cr>", { buffer = buffer, desc = "Close Julia environment" })

  local lines = {
    "Julia environment",
    "",
    "Active project: " .. (context.active_project or "(Julia default)"),
    "Workspace:      " .. context.workspace,
    "",
    "Load path, in order:",
  }
  for _, entry in ipairs(context.load_path) do
    lines[#lines + 1] = "  " .. entry
  end
  vim.list_extend(lines, { "", "Depots, in order:" })
  for _, entry in ipairs(context.depot_path) do
    lines[#lines + 1] = "  " .. (entry ~= "" and entry or "(Julia system depots)")
  end
  vim.list_extend(lines, { "", "Packages declared by project files in the stack:" })
  vim.api.nvim_buf_set_lines(buffer, 0, -1, false, lines)
  vim.bo[buffer].modifiable = false

  projects.package_origins(context, function(origins, problems)
    if not vim.api.nvim_buf_is_valid(buffer) then
      return
    end
    local entries = {}
    local names = vim.tbl_keys(origins)
    table.sort(names)
    for _, name in ipairs(names) do
      entries[#entries + 1] = ("  %s  %s"):format(name, vim.fn.fnamemodify(origins[name], ":~"))
    end
    if #entries == 0 then
      entries[1] = "  (none found)"
    end
    vim.list_extend(entries, problems)
    vim.bo[buffer].modifiable = true
    vim.api.nvim_buf_set_lines(buffer, -1, -1, false, entries)
    vim.bo[buffer].modifiable = false
  end)
end, { desc = "Show the Julia project stack, depots, and package origins" })
