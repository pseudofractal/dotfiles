{}: {
  programs.nvf = {
    enable = true;
    settings = {
      vim.viAlias = true;
      vim.vimAlias = false;
      vim.lsp = {
        enable = true;
      };
      vim.autocomplete = {
        blink-cmp = {
          enable = true;
          friendly-snippets.enable = true;
        };
      };
      vim.languages = {
        rust = {
          enable = true;
          treesitter.enable = true;
          dap.enable = true;
          lsp = {
            enable = true;
            opts = ''
              ['rust-analyzer'] = {
                cargo = {allFeature = true},
                checkOnSave = true,
                procMacro = {
                  enable = true,
                },
              },
            '';
          };
          extensions.crates-nvim.enable = true;
        };
        nix = {
          enable = true;
          treesitter.enable = true;
          extraDiagnostics.enable = true;
          format.enable = true;
          lsp.enable = true;
        };
        python = {
          enable = true;
          dap.enable = true;
          format = {
            enable = true;
            type = [
              "ruff"
              "ruff-check"
            ];
          };
          lsp.enable = true;
          treesitter.enable = true;
        };
      };
    };
  };
}
