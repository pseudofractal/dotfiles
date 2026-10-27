{
  config,
  isAndroid,
  lib,
  pkgs,
  ...
}: let
  terminalEditor = pkgs.writeShellApplication {
    name = "nvim-terminal";
    text = ''
      exec ${lib.getExe config.programs.kitty.package} \
        --class neovim --title Neovim --directory "$PWD" \
        ${lib.getExe config.programs.neovim.finalPackage} "$@"
    '';
  };
  languageServers = with pkgs; [
    # keep-sorted start
    astro-language-server
    biome
    clang-tools
    harper
    lua-language-server
    marksman
    nixd
    rust-analyzer
    taplo
    tinymist
    ty
    # keep-sorted end
  ];

  linters = with pkgs; [
    # keep-sorted start
    cpplint
    cspell
    luaPackages.luacheck
    markdownlint-cli2
    shellcheck
    # keep-sorted end
  ];

  codelldb = pkgs.writeShellApplication {
    name = "codelldb";
    runtimeInputs = [pkgs.vscode-extensions.vadimcn.vscode-lldb];
    text = ''
      exec "${pkgs.vscode-extensions.vadimcn.vscode-lldb}/lib/vscode/extensions/vadimcn.vscode-lldb/adapter/codelldb" "$@"
    '';
  };
in {
  # defaultEditor also sets VISUAL to bare nvim; graphical callers need Kitty.
  home.sessionVariables.VISUAL = lib.mkForce (
    if isAndroid
    then "nvim"
    else lib.getExe terminalEditor
  );

  programs.neovim = {
    enable = true;
    defaultEditor = true;
    viAlias = true;
    vimAlias = true;
    withRuby = true;
    withNodeJs = true;
    withPython3 = true;
    plugins = [];
    extraWrapperArgs =
      ["--set" "JULIA_NUM_THREADS" "4"]
      ++ lib.optionals (!isAndroid) ["--set" "LLAMA_LOCAL_ENABLE" "1"];
  };

  home.packages = with pkgs;
    [
      # keep-sorted start
      chromium
      fd
      fzf
      gcc
      gnumake
      go
      imagemagick
      nodejs
      python3
      ripgrep
      tree-sitter
      unzip
      xclip
      # keep-sorted end
    ]
    ++ languageServers
    ++ [codelldb]
    ++ linters
    ++ lib.optionals (!isAndroid) [terminalEditor];

  xdg.configFile."nvim" = {
    source = ./config;
    recursive = true;
  };
}
