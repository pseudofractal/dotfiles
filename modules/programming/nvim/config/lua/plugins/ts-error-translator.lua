return {
  "dmmulroy/ts-error-translator.nvim",
  -- Diagnostics can arrive before the first TypeScript buffer attaches, so the
  -- handler has to be installed at startup.
  lazy = false,
  opts = {
    auto_attach = true,
    servers = {
      "astro",
      "svelte",
      "ts_ls",
      "tsc",
      "typescript-tools",
      "volar",
      "vtsls",
    },
  },
  config = function(_, opts)
    require("ts-error-translator").setup(opts)

    -- The native `tsc` server answers `textDocument/diagnostic` (pull) instead
    -- of pushing, so the plugin's publishDiagnostics hook never sees those
    -- messages. Translate the pulled items here as well.
    local servers = opts.servers or {}
    local on_diagnostic = vim.lsp.handlers["textDocument/diagnostic"]

    vim.lsp.handlers["textDocument/diagnostic"] = function(err, result, ctx, config)
      local client = ctx.client_id and vim.lsp.get_client_by_id(ctx.client_id)
      if result and result.items and client and vim.tbl_contains(servers, client.name) then
        for _, item in ipairs(result.items) do
          if item.message and item.code then
            local parsed =
              require("ts-error-translator").parse_errors("TS" .. tostring(item.code) .. ": " .. item.message)
            if parsed[1] and parsed[1].improvedError then
              item.message = parsed[1].improvedError.body
            end
          end
        end
      end
      return on_diagnostic(err, result, ctx, config)
    end
  end,
}
