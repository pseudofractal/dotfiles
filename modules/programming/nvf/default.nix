{
  config,
  lib,
  pkgs,
  ...
}: {
  imports = [
    # keep-sorted start
    ./keymaps.nix
    ./languages.nix
    ./lsp.nix
    ./mini.nix
    ./telescope.nix
    ./yazi.nix
    # keep-sorted end
  ];

  programs.nvf.settings.vim = {
    viAlias = lib.mkForce false;
    vimAlias = lib.mkForce false;

    autocomplete = {
      blink-cmp = {
        enable = true;
        friendly-snippets.enable = true;
        setupOpts.signature.enabled = true;
      };
    };

    git = {
      gitsigns.enable = true;
    };

    theme = {
      enable = true;
      name = "catppuccin";
      style = "mocha";
      transparent = true;
    };

    treesitter = {
      enable = true;
      fold = true;
      textobjects.enable = true;
      autotagHtml = true;
      context.enable = true;
    };

    notify.nvim-notify = {
      enable = true;
      setupOpts.timeout = 3000;
    };

    options = {
      tabstop = 2;
    };

    vendoredKeymaps.enable = false;
  };

  home.packages = [
    (pkgs.writeShellScriptBin "nvf" ''
      exec ${config.programs.nvf.settings.vim.build.finalPackage}/bin/nvim "$@"
    '')
  ];
}
