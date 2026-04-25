{
  lib,
  pkgs,
  ...
}: let
  extensions = [
    "astro"
    "fish"
    "julia"
    "latex"
    "lua"
    "typst"
    "nix"
    "svelte"
    "quarto"
    "qml"
  ];

  lspPackages = [
    # keep-sorted start
    "lua-language-server"
    "nixd"
    "package-version-server"
    "rust-analyzer"
    "svelte-language-server"
    "texlab"
    "tinymist"
    # keep-sorted end
  ];
in {
  programs.zed-editor = {
    enable = true;

    inherit extensions;

    extraPackages = with pkgs; [
      alejandra
      astro-language-server
      kdePackages.qtdeclarative
      lua-language-server
      nixd
      package-version-server
      ruff
      rust-analyzer
      svelte-language-server
      tailwindcss-language-server
      texlab
      tinymist
      ty
    ];

    userSettings = {
      buffer_font_family = "Maple Mono NF CN";
      buffer_font_size = 18;
      ui_font_family = "Maple Mono NF CN";
      ui_font_size = 18;

      vim_mode = true;
      cursor_shape = "bar";
      git.inline_blame.enabled = false;

      minimap = {
        show = "always";
        thumb = "always";
      };

      tab_size = 2;
      tabs = {
        file_icons = true;
        git_status = true;
      };
      terminal = {
        detect_venv.on.activate_script = "fish";
        cursor_shape = "bar";
        toolbar.breadcrumbs = false;
        line_height = "comfortable";
      };

      unnecessary_code_fade = 0.5;
      use_smartcase_search = true;

      auto_install_extensions = lib.genAttrs extensions (_: false);

      lsp =
        lib.mergeAttrsList (
          map (name: {
            ${name}.binary.path = lib.getExe pkgs.${name};
          })
          lspPackages
        )
        // {
          astro-language-server.binary = {
            path = lib.getExe pkgs.astro-language-server;
            arguments = ["--stdio"];
          };

          ruff.binary = {
            path = lib.getExe pkgs.ruff;
            arguments = ["server"];
          };

          tailwindcss-language-server.binary = {
            path = lib.getExe pkgs.tailwindcss-language-server;
            arguments = ["--stdio"];
          };

          ty.binary = {
            path = lib.getExe pkgs.ty;
            arguments = ["server"];
          };
        };
    };
  };
}
