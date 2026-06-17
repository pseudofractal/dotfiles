{pkgs, ...}: {
  programs.neovim = {
    enable = true;
    defaultEditor = true;
    viAlias = true;
    vimAlias = true;
    withRuby = true;
    withNodeJs = true;
    withPython3 = true;
    plugins = with pkgs.vimPlugins; [
      nvim-treesitter.withAllGrammars
      (nvim-treesitter-textobjects.overrideAttrs (old: {
        doCheck = false;
      }))
    ];
  };

  home.packages = with pkgs; [
    # keep-sorted start
    chromium
    fd
    fzf
    gcc
    gnumake
    nodejs
    python3
    ripgrep
    tree-sitter
    unzip
    xclip
    # keep-sorted end

    # LSPs
    # keep-sorted start
    astro-language-server
    biome
    clang-tools
    lua-language-server
    marksman
    nixd
    rust-analyzer
    taplo
    tinymist
    ty
    # keep-sorted end

    # DAP
    (pkgs.writeShellApplication {
      name = "codelldb";
      runtimeInputs = [pkgs.vscode-extensions.vadimcn.vscode-lldb];
      text = ''
        exec "${pkgs.vscode-extensions.vadimcn.vscode-lldb}/lib/vscode/extensions/vadimcn.vscode-lldb/adapter/codelldb" "$@"
      '';
    })

    # Linters
    # keep-sorted start
    cpplint
    cspell
    luaPackages.luacheck
    markdownlint-cli2
    shellcheck
    # keep-sorted end
  ];

  xdg.configFile."nvim" = {
    source = ./config;
    recursive = true;
  };
}
