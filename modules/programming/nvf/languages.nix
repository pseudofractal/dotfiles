{...}: {

  programs.nvf.settings.vim.languages = {
    enableDAP = true;
    enableExtraDiagnostics = true;
    enableFormat = true;
    enableTreesitter = true;

    bash.enable = true;
    css = {
      enable = true;
      format = {
        enable = true;
        type = ["biome"];
      };
    };
    html.enable = true;
    json.enable = true;
    julia.enable = true;
    lua.enable = true;
    markdown = {
      enable = true;
      extensions = {
        markview-nvim.enable = true;
      };
    };
    nix.enable = true;
    python = {
      enable = true;
      format.type = [
        "ruff"
        "ruff-check"
      ];
      lsp.servers = ["ty"];
    };
    rust = {
      enable = true;
      lsp.opts = ''
        ['rust-analyzer'] = {
          cargo = {allFeature = true},
          checkOnSave = true,
          procMacro = {
            enable = true,
          },
        },
      '';
      extensions.crates-nvim.enable = true;
    };
    svelte = {
      enable = true;
      format.type = ["biome"];
    };
    toml.enable = true;
    typescript = {
      enable = true;
      lsp.servers = ["deno"];
      format.type = ["biome"];
      extraDiagnostics.types = ["biomejs"];
      extensions.ts-error-translator = {
        enable = true;
        setupOpts = {
          auto_override_publish_diagnostics = false;
          auto_attach = true;
        };
      };
    };
    typst.enable = true;
  };
}
