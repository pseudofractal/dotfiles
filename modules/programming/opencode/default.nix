{
  config,
  lib,
  pkgs,
  ...
}: let
  typescriptLib = "${pkgs.typescript}/lib/node_modules/typescript/lib";
  jetls = "${config.home.homeDirectory}/.julia/bin/jetls";
  lsp = {
    astro = {
      command = [(lib.getExe pkgs.astro-language-server) "--stdio"];
      initialization = {
        typescript = {
          tsdk = typescriptLib;
        };
      };
    };

    bash = {
      command = [(lib.getExe pkgs.bash-language-server) "start"];
      extensions = [
        ".sh"
        ".bash"
        ".zsh"
        ".ksh"
        ".envrc"
      ];
    };

    "fish-lsp" = {
      command = [(lib.getExe pkgs.fish-lsp) "start"];
      extensions = [".fish"];
    };

    glsl = {
      command = [(lib.getExe pkgs.glsl_analyzer)];
      extensions = [
        ".glsl"
        ".vert"
        ".tesc"
        ".tese"
        ".geom"
        ".frag"
        ".comp"
      ];
    };

    jdtls.command = [(lib.getExe pkgs.jdt-language-server)];

    julials = {
      command = [
        jetls
        "serve"
      ];
      extensions = [".jl"];
    };

    "kotlin-ls".command = [(lib.getExe pkgs.kotlin-language-server)];

    marksman = {
      command = [(lib.getExe pkgs.marksman) "server"];
      extensions = [
        ".md"
        ".markdown"
      ];
    };

    qmlls = {
      command = [(lib.getExe' pkgs.kdePackages.qtdeclarative "qmlls")];
      extensions = [".qml"];
    };

    sqls = {
      command = [(lib.getExe pkgs.sqls)];
      extensions = [".sql"];
    };

    taplo = {
      command = [(lib.getExe pkgs.taplo) "lsp" "stdio"];
      extensions = [".toml"];
    };

    tinymist = {
      command = [(lib.getExe pkgs.tinymist)];
      extensions = [
        ".typ"
        ".typc"
        ".typst"
      ];
    };

    texlab = {
      command = [(lib.getExe pkgs.texlab)];
      extensions = [
        ".tex"
        ".sty"
        ".cls"
        ".bib"
        ".cmh"
      ];
    };

    typescript = {
      command = [(lib.getExe pkgs.typescript-language-server) "--stdio"];
      initialization = {
        tsserver = {
          path = "${typescriptLib}/tsserver.js";
        };
      };
    };
  };
in {
  imports = [
    # keep-sorted start
    #./tools
    ./mcps.nix
    ./rules
    ./skills
    # keep-sorted end
  ];

  programs.opencode = {
    enable = true;
    enableMcpIntegration = true;

    tui.theme = "catppuccin";

    settings = {
      logLevel = "INFO";
      inherit lsp;
      provider = {
        "llama.cpp" = {
          npm = "@ai-sdk/openai-compatible";
          name = "llama-server (local)";
          options.baseURL = "http://127.0.0.1:8012/v1";
          models.local = {
            name = "Local GGUF model";
            limit = {
              context = 4096;
              output = 4096;
            };
          };
        };
      };
      plugin = [
        # keep-sorted start
        "@mohak34/opencode-notifier@latest"
        "opencode-gemini-auth@latest"
        "opencode-openai-codex-auth@latest"
        # keep-sorted end
      ];
    };
  };

  home.packages = with pkgs; [
    # keep-sorted start
    astro-language-server
    bash-language-server
    biome
    clang-tools
    fish-lsp
    glsl_analyzer
    gopls
    jdt-language-server
    kdePackages.qtdeclarative
    kotlin-language-server
    lua-language-server
    marksman
    mcp-nixos
    nixd
    pyright
    rust-analyzer
    sqls
    svelte-language-server
    taplo
    texlab
    tinymist
    typescript
    typescript-language-server
    vue-language-server
    yaml-language-server
    # keep-sorted end
  ];

  home.sessionVariables = {
    OPENCODE_EXPERIMENTAL = "true";
    OPENCODE_DISABLE_LSP_DOWNLOAD = "true";
    CODEX_INTERNAL_ORIGINATOR_OVERRIDE = "Codex Desktop";
  };
}
