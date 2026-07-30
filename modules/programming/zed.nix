{
  lib,
  pkgs,
  inputs,
  ...
}: let
  treefmtEval = inputs.treefmt-nix.lib.evalModule pkgs ../../treefmt.nix;
  extensions = [
    # keep-sorted start
    "astro"
    "cargo-tom"
    "catppuccin"
    "catppuccin-icons"
    "fish"
    "harper"
    "julia"
    "latex"
    "lua"
    "nix"
    "qml"
    "quarto"
    "rainbow-csv"
    "svelte"
    "typst"
    # keep-sorted end
  ];

  lspPackages = [
    # keep-sorted start
    "kotlin-language-server"
    "lua-language-server"
    "nixd"
    "package-version-server"
    "rust-analyzer"
    "svelte-language-server"
    "texlab"
    "tinymist"
    # keep-sorted end
  ];

  treefmtStdin = pkgs.writeShellApplication {
    name = "treefmt-stdin";
    runtimeInputs = with pkgs; [coreutils treefmtEval.config.build.wrapper];
    text = ''
      tmpfile=$(mktemp "''${1:+.''${1##*.}}")
      cat > "''$tmpfile"
      treefmt "''$tmpfile"
      cat "''$tmpfile"
      rm -f "''$tmpfile"
    '';
  };
in {
  programs.zed-editor = {
    enable = true;

    inherit extensions;

    extraPackages = with pkgs; [
      # keep-sorted start
      alejandra
      astro-language-server
      harper
      kdePackages.qtdeclarative
      keep-sorted
      kotlin-language-server
      lua-language-server
      nil
      nixd
      package-version-server
      ruff
      rust-analyzer
      svelte-language-server
      tailwindcss-language-server
      texlab
      tinymist
      treefmtStdin
      # keep-sorted end
    ];

    userSettings = {
      buffer_font_family = "Maple Mono NF CN";
      buffer_font_size = 18;
      ui_font_family = "Maple Mono NF CN";
      ui_font_size = 18;

      vim_mode = true;
      cursor_shape = "bar";
      git.inline_blame.enabled = true;

      minimap = {
        show = "never";
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

      format_on_save = "on";
      formatter = {
        external = {
          command = lib.getExe treefmtStdin;
          arguments = ["{buffer_path}"];
        };
      };

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

          kotlin-language-server.binary = {
            path = lib.getExe pkgs.kotlin-language-server;
          };

          harper-ls = {
            binary = {
              path = "${pkgs.harper}/bin/harper-ls";
            };
            settings = {
              "harper-ls" = {
                userDictPath = "~/dotfiles/misc/harper/dictionary.txt";
              diagnosticSeverity = "hint";
                dialect = "American";
                maxFileLength = 120000;
                excludePatterns = [
                  "**/node_modules/**"
                  "**/vendor/**"
                  "**/dist/**"
                  "**/build/**"
                  "**/target/**"
                  "**/.git/**"
                  "**/*.lock"
                  "**/CHANGELOG.*"
                  "**/TODO.*"
                  "**/.env*"
                  "**/.gitignore"
                ];
              };
            };
          };
        };
    };
  };
}
