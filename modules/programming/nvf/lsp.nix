{...}: {
  programs.nvf.settings.vim.lsp = {
    enable = true;
    formatOnSave = true;
    inlayHints.enable = true;
    lspkind.enable = true;
    lspsaga.enable = true;
    nvim-docs-view.enable = true;
    otter-nvim.enable = true;

    trouble.enable = true;

    servers = {
      bash-language-server.filetypes = [
        # keep-sorted start
        "bash"
        "sh"
        "zsh"
        # keep-sorted end
      ];
      deno.filetypes = [
        # keep-sorted start
        "javascript"
        "javascriptreact"
        "typescript"
        "typescriptreact"
        # keep-sorted end
      ];
      marksman.filetypes = ["markdown"];
      superhtml.filetypes = [
        "html"
        "xhtml"
      ];
    };
  };
}
