{
  config,
  lib,
  pkgs,
  inputs,
  isAndroid,
  ...
}: let
  upstream = inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.opencode2;
  # llm-agents names the executable opencode2. Keep one canonical command for
  # terminal use, editor integrations, and T3's version detection.
  opencode = pkgs.symlinkJoin {
    name = "opencode-${upstream.version}";
    inherit (upstream) version;
    paths = [upstream];
    nativeBuildInputs = [pkgs.makeWrapper];
    postBuild = ''
      makeWrapper ${lib.getExe upstream} "$out/bin/opencode" \
        --set-default OPENCODE_LOG_LEVEL info \
        ${lib.optionalString (!isAndroid) "--suffix PATH : ${lib.makeBinPath [pkgs.libnotify pkgs.mpv]}"}
    '';
    meta = upstream.meta // {mainProgram = "opencode";};
  };
  # V2 shape for one server: keep all of the server's own attributes (url,
  # enabled, …), tag it remote/local, and for local servers collapse the V1
  # command+args into a command list and render file-backed env as
  # `environment`. Runs as an HM extraTransform, so it still sees the raw V1
  # keys (including file refs in env) before `exclude` drops args/env.
  toV2Server = server:
    server
    // {
      type =
        if server.url != null
        then "remote"
        else "local";
    }
    // lib.optionalAttrs (server.url == null) {
      command = [server.command] ++ server.args;
      environment = lib.hm.mcp.renderEnv (path: "{file:${path}}") server.env;
    };
  # The pinned Home Manager integration emits V1 MCP keys. Render the same
  # shared server definitions into V2's mcp.servers map instead, with HM's
  # enabled-state resolution mapped onto V2's `disabled` flag.
  toMcpServer = _: server: let
    converted = lib.hm.mcp.transformMcpServer {
      inherit server;
      exclude = ["args" "env"];
      extraTransforms = [toV2Server];
    };
  in
    removeAttrs converted ["enabled"]
    // lib.optionalAttrs (converted ? enabled) {disabled = !converted.enabled;};
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
  imports = [./cli.nix];

  programs.opencode = {
    enable = true;
    package = opencode;
    enableMcpIntegration = false;

    settings = {
      update = "disable";
      # Kept as a reference for the configured language servers. V2 accepts
      # this map but currently does not run LSPs or produce their diagnostics.
      inherit lsp;
      mcp.servers = lib.mapAttrs toMcpServer config.programs.mcp.servers;
      permissions = [
        {
          action = "external_directory";
          resource = "*";
          effect = "ask";
        }
      ];
      experimental.todo = true;
      plugins = [
        # keep-sorted start
        "@mohak34/opencode-notifier@latest"
        "opencode-gemini-auth@latest"
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
}
