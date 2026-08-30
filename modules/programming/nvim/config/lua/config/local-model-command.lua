local models = {
  "qwen2.5-coder-1.5b-q5_k_m.gguf",
  "qwen2.5-coder-3b-q4_k_m.gguf",
  "Mellum2-12B-A2.5B-Instruct-Q4_K_M.gguf",
}

local function restart_editors(model)
  vim.system({ "llama-model", model }, { text = true }, function(result)
    if result.code ~= 0 then
      vim.schedule(function()
        vim.notify(result.stderr ~= "" and result.stderr or "Unable to switch local model", vim.log.levels.ERROR)
      end)
      return
    end

    local function wait_for_server(attempt)
      vim.system({ "curl", "-fsS", "http://127.0.0.1:8012/health" }, { text = true }, function(health)
        if health.code == 0 then
          vim.schedule(function()
            vim.cmd("CursortabRestart")
            if vim.fn.exists(":NextEditRestart") == 2 then
              vim.cmd("NextEditRestart")
            end
            vim.notify("Local model ready: " .. model)
          end)
        elseif attempt < 60 then
          vim.defer_fn(function()
            wait_for_server(attempt + 1)
          end, 500)
        else
          vim.schedule(function()
            vim.notify("Timed out waiting for local model: " .. model, vim.log.levels.ERROR)
          end)
        end
      end)
    end

    wait_for_server(0)
  end)
end

vim.api.nvim_create_user_command("LocalModel", function(args)
  restart_editors(args.args)
end, {
  nargs = 1,
  complete = function()
    return models
  end,
  desc = "Switch the local llama.cpp model and restart editor integrations",
})
