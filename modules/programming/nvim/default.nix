{
  pkgs,
  ...
}: {
  programs.neovim = {
    enable = true;
    defaultEditor = true;
    viAlias = true;
    vimAlias = true;
    withNodeJs = true;
    withPython3 = true;
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

    # Formatters & Linters
    stylua # Lua
    ruff # Python
    black # Python
    isort # Python (Imports)
    prettierd # JS/TS/HTML/CSS
    alejandra # Nix formatter
    markdownlint-cli2 # Markdown
    cpplint # C++ linter
    shfmt # Shell formatter
    shellcheck # Shell linter
    rustfmt # Rust
    mdformat # Markdown
    biome # JS
  ];

  xdg.configFile."nvim" = {
    source = ./config;
    recursive = true;
  };
}
