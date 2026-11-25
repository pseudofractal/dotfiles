local M = {}
local project_cache = {}

M.root_markers = { { "JuliaProject.toml", "Project.toml" }, ".git" }

function M.project_file(dir)
  for _, filename in ipairs({ "JuliaProject.toml", "Project.toml" }) do
    local path = vim.fs.joinpath(dir, filename)
    if vim.fn.filereadable(path) == 1 then
      return path
    end
  end
end

function M.stack(workspace_root, repo_root)
  local projects = {}
  local function add_project(dir)
    local path = M.project_file(dir)
    if path and not vim.tbl_contains(projects, path) then
      projects[#projects + 1] = path
    end
  end

  add_project(workspace_root)
  local home = vim.fs.normalize(vim.env.HOME)
  for ancestor in vim.fs.parents(workspace_root) do
    local inside_home = ancestor == home or vim.startswith(ancestor, home .. "/")
    if workspace_root == home or not inside_home then
      break
    end
    add_project(ancestor)
    if ancestor == home then
      break
    end
  end

  add_project(vim.fs.joinpath(repo_root, "scripts"))
  return projects
end

function M.executable()
  for _, variable in ipairs({ "JETLS_JULIA_CMD", "JULIA_APPS_JULIA_CMD" }) do
    local path = vim.env[variable]
    if path and path ~= "" then
      return path
    end
  end
  return vim.fn.exepath("julia")
end

function M.context(workspace, repository)
  workspace = vim.fs.normalize(vim.fn.fnamemodify(workspace, ":p")):gsub("([^/])/$", "%1")
  repository = repository or vim.fs.root(workspace, ".git") or workspace
  local active_project = M.project_file(workspace)
  local stack = M.stack(workspace, repository)
  local load_path = { "@" }
  for _, file in ipairs(stack) do
    if file ~= active_project then
      load_path[#load_path + 1] = vim.fs.dirname(file)
    end
  end
  vim.list_extend(load_path, { "@v#.#", "@stdlib" })
  local depot_path = {
    vim.fs.joinpath(repository, ".julia-depot"),
    vim.fs.joinpath(vim.env.HOME, ".julia"),
    "",
  }
  return {
    workspace = workspace,
    repository = repository,
    active_project = active_project,
    projects = stack,
    load_path = load_path,
    depot_path = depot_path,
    env = {
      JULIA_PROJECT = active_project and workspace or "",
      JULIA_LOAD_PATH = table.concat(load_path, ":"),
      JULIA_DEPOT_PATH = table.concat(depot_path, ":"),
      XDG_CACHE_HOME = vim.fs.joinpath(repository, ".cache"),
    },
  }
end

function M.for_buffer(bufnr, project)
  local file = vim.api.nvim_buf_get_name(bufnr)
  local dir = file ~= "" and vim.fs.dirname(file) or vim.fn.getcwd()
  local repository = vim.fs.root(dir, ".git")
  return M.context(project or vim.fs.root(dir, M.root_markers) or dir, repository)
end

local function read_package_names(path, callback)
  local stat = vim.uv.fs_stat(path)
  if not stat then
    return callback(nil, "Project file is missing")
  end
  local revision = table.concat({ stat.ino, stat.size, stat.mtime.sec, stat.mtime.nsec }, ":")
  local cached = project_cache[path]
  if cached and cached.revision == revision then
    if cached.names then
      return callback(cached.names)
    end
    table.insert(cached.waiting, callback)
    return
  end

  local entry = { revision = revision, waiting = { callback } }
  project_cache[path] = entry
  vim.system(
    { "taplo", "get", "--file-path", path, "--output-format", "json" },
    { text = true },
    vim.schedule_wrap(function(result)
      local ok, project = pcall(vim.json.decode, result.stdout or "")
      local names, problem
      if result.code == 0 and ok and type(project) == "table" then
        names = type(project.deps) == "table" and vim.tbl_keys(project.deps) or {}
        if type(project.name) == "string" then
          names[#names + 1] = project.name
        end
        table.sort(names)
        entry.names = names
      else
        problem = "Unable to read Julia project"
        if project_cache[path] == entry then
          project_cache[path] = nil
        end
      end
      local waiting = entry.waiting
      entry.waiting = nil
      for _, notify in ipairs(waiting) do
        notify(names, problem)
      end
    end)
  )
end

function M.package_origins(context, callback)
  local pending = #context.projects
  if pending == 0 then
    return callback({}, {})
  end
  if vim.fn.executable("taplo") ~= 1 then
    return callback({}, { "Taplo is unavailable" })
  end

  local names_by_project, problems = {}, {}
  for i, path in ipairs(context.projects) do
    read_package_names(path, function(names, problem)
      names_by_project[i] = names or {}
      if problem then
        problems[#problems + 1] = problem .. ": " .. path
      end
      pending = pending - 1
      if pending ~= 0 then
        return
      end
      local origins = {}
      for index, package_names in ipairs(names_by_project) do
        for _, name in ipairs(package_names) do
          origins[name] = origins[name] or context.projects[index]
        end
      end
      callback(origins, problems)
    end)
  end
end

return M
