{
  config,
  lib,
  pkgs,
  isAndroid,
  ...
}: let
  modelDir = "${config.home.homeDirectory}/.local/share/llm-models";
  stateDir = "${config.xdg.stateHome}/llama-cpp";
  selectedModel = "${stateDir}/model";
  llamaCpp = pkgs.llama-cpp.override {cudaSupport = true;};
  arxivMcpSrc = pkgs.fetchFromGitHub {
    owner = "takashiishida";
    repo = "arxiv-latex-mcp";
    rev = "HEAD";
    hash = "sha256-kPUCATcZlspS7vl5EiFh18MDvlftMQFi90LXIxjmgbo=";
  };
  mcpConfig = pkgs.writeText "llama-mcp.json" (builtins.toJSON {
    mcpServers = {
      context7 = {
        command = "${pkgs.nodejs}/bin/npx";
        args = ["-y" "mcp-remote" "https://mcp.context7.com/mcp"];
      };
      playwright = {
        command = "${pkgs.nodejs}/bin/npx";
        args = ["-y" "@playwright/mcp@latest" "--isolated" "--headless"];
      };
      web-search = {
        command = "${pkgs.nodejs}/bin/npx";
        args = ["-y" "fast-web-search-mcp"];
      };
      fetch = {
        command = "${pkgs.uv}/bin/uvx";
        args = ["mcp-server-fetch"];
      };
      arxiv = {
        command = "${pkgs.uv}/bin/uv";
        args = ["run" "--directory" "${arxivMcpSrc}" "server/main.py"];
        env = {
          UV_PROJECT_ENVIRONMENT = "${config.home.homeDirectory}/.cache/uv-venvs/arxiv_mcp";
        };
      };
      nix = {
        command = "${pkgs.mcp-nixos}/bin/mcp-nixos";
        args = [];
      };
    };
  });

  llamaServer = pkgs.writeShellApplication {
    name = "llama-server-selected";
    runtimeInputs = [llamaCpp pkgs.coreutils];
    text = ''
      set -euo pipefail

      model="$(cat ${selectedModel} 2>/dev/null || true)"
      if [ -z "$model" ] || [[ "$model" == */* ]]; then
        echo "No valid model selected. Run: llama-model <model filename>" >&2
        exit 1
      fi

      model_path="${modelDir}/$model"

      if [ ! -f "$model_path" ]; then
        echo "Model file not found: $model_path" >&2
        exit 1
      fi

      exec ${llamaCpp}/bin/llama-server \
        --model "$model_path" \
         --host 127.0.0.1 \
         --port 8012 \
         --alias local \
         --parallel 1 \
          --ctx-size 4096 \
          --batch-size 128 \
          --ubatch-size 32 \
          --flash-attn on \
          --n-gpu-layers auto \
          --ui-config '{"theme":"dark","pasteLongTextToFileLen":0,"renderUserContentAsMarkdown":true}' \
          --mcp-servers-config "${mcpConfig}" \
          --tools read_file,file_glob_search,grep_search,exec_shell_command,write_file,edit_file,get_info
    '';
  };

  selectModel = pkgs.writeShellApplication {
    name = "llama-model";
    runtimeInputs = [pkgs.coreutils pkgs.systemd];
    text = ''
      set -euo pipefail

       model="''${1:-}"
       if [ -z "$model" ]; then
         echo "Usage: llama-model <model filename>" >&2
         printf 'Available models:\n' >&2
         for path in "${modelDir}"/*.gguf; do
           [ -f "$path" ] && printf '  %s\n' "''${path##*/}" >&2
         done
         exit 2
       fi

       if [[ "$model" == */* || "$model" != *.gguf ]]; then
         echo "Model must be a .gguf filename in ${modelDir}" >&2
         exit 2
       fi

       if [ ! -f "${modelDir}/$model" ]; then
         echo "Model file not found: ${modelDir}/$model" >&2
         exit 1
       fi

      mkdir -p "${stateDir}"
      printf '%s\n' "$model" > "${selectedModel}"
      systemctl --user restart llama-server.service
      echo "Started $model on http://127.0.0.1:8012"
    '';
  };
in {
  config = lib.mkIf (!isAndroid) {
    home.packages = [llamaCpp selectModel];
    home.sessionVariables.LLAMA_LOCAL_ENABLE = "1";

    systemd.user.services.llama-server = {
      Unit = {
        Description = "Local llama.cpp inference server";
        After = ["graphical-session.target"];
      };
      Service = {
        Type = "simple";
        ExecStart = "${llamaServer}/bin/llama-server-selected";
        Environment = [
          "LD_LIBRARY_PATH=/usr/lib"
          "GGML_BACKEND_PATH=${llamaCpp}/bin/libggml-cuda.so"
        ];
        Restart = "on-failure";
        RestartSec = 3;
      };
    };
  };
}
