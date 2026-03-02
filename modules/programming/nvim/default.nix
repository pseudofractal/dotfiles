{pkgs, ...}: {
  programs.neovim = {
    enable = true;
    defaultEditor = true;
    viAlias = true;
    vimAlias = true;
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
    gcc
    gnumake
    unzip
    ripgrep
    fd
    xclip
    fzf
    yazi
    nodejs
    python3
    tree-sitter

    # LSPs
    lua-language-server # lua_ls
    rust-analyzer # rust_analyzer
    basedpyright # basedpyright
    tinymist # tinymist (Typst)
    marksman # marksman (Markdown)
    biome # biome (JS/TS)
    clang-tools # clangd
    taplo # taplo (TOML)
    nixd # nixd (Nix)
    astro-language-server # astro (Astro)

    # Formatters & Linters
    cspell # Spell checker
    stylua # Lua
    ruff # Python
    prettierd # JS/TS/HTML/CSS
    alejandra # Nix formatter
    markdownlint-cli2 # Markdown
    cpplint # C++ linter
    shfmt # Shell formatter
    shellcheck # Shell linter
    rustfmt # Rust
    mdformat # Markdown
    biome # JS
    typstyle # Typst
  ];

  xdg.configFile."nvim" = {
    source = ./config;
    recursive = true;
  };
}
