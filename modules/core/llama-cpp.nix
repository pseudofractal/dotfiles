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

  llamaServer = pkgs.writeShellApplication {
    name = "llama-server-selected";
    runtimeInputs = [llamaCpp pkgs.coreutils];
    text = ''
      set -euo pipefail

      model="$(cat ${selectedModel} 2>/dev/null || true)"
      case "$model" in
        light)
          model_path="${modelDir}/qwen2.5-coder-1.5b-q5_k_m.gguf"
          gpu_layers=999
          ctx_size=4096
          batch_size=512
          ubatch_size=128
          ;;
        balanced)
          model_path="${modelDir}/qwen2.5-coder-3b-q4_k_m.gguf"
          gpu_layers=999
          ctx_size=4096
          batch_size=512
          ubatch_size=128
          ;;
        smart)
          model_path="${modelDir}/Mellum2-12B-A2.5B-Instruct-Q4_K_M.gguf"
          gpu_layers=0
          ctx_size=2048
          batch_size=128
          ubatch_size=32
          ;;
        *)
          echo "No model selected. Run: llama-model <model filename>" >&2
          exit 1
          ;;
      esac

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
         --ctx-size "$ctx_size" \
         --batch-size "$batch_size" \
         --ubatch-size "$ubatch_size" \
         --flash-attn on \
         --n-gpu-layers "$gpu_layers"
    '';
  };

  selectModel = pkgs.writeShellApplication {
    name = "llama-model";
    runtimeInputs = [pkgs.coreutils pkgs.systemd];
    text = ''
      set -euo pipefail

       case "''${1:-}" in
         qwen2.5-coder-1.5b-q5_k_m.gguf) model="light" ;;
         qwen2.5-coder-3b-q4_k_m.gguf) model="balanced" ;;
         Mellum2-12B-A2.5B-Instruct-Q4_K_M.gguf) model="smart" ;;
         *)
           echo "Usage: llama-model <model filename>" >&2
           echo "Models: qwen2.5-coder-1.5b-q5_k_m.gguf | qwen2.5-coder-3b-q4_k_m.gguf | Mellum2-12B-A2.5B-Instruct-Q4_K_M.gguf" >&2
           exit 2
          ;;
      esac

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
