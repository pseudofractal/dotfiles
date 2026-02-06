{
  pkgs,
  inputs,
  config,
  ...
}: let
  system = pkgs.stdenv.hostPlatform.system;
  package = inputs.opencode.packages.${system}.default;
  opencode-wrapped = pkgs.symlinkJoin {
    name = "opencode";
    paths = [package];
    buildInputs = [pkgs.makeWrapper];
    postBuild = ''
      rm $out/bin/opencode
      makeWrapper ${package}/bin/opencode $out/bin/opencode \
        --prefix PATH : "${pkgs.fish}/bin" \
        --set OPENCODE_DISABLE_LSP_DOWNLOAD "true" \
        --set OPENCODE_EXPERIMENTAL "true"
    '';
  };
in {
  home.packages = [
    opencode-wrapped
  ];
  sops.secrets.z_ai_api_key = {};
  sops.templates."opencode.json" = {
    content = builtins.toJSON {
      "$schema" = "https://opencode.ai/config.json";
      "plugin" = ["opencode-gemini-auth@latest"];
      lsp = {
      };
      mcp = {
        zai-mcp-server = {
          type = "local";
          command = ["${pkgs.nodejs_22}/bin/npx" "-y" "@z_ai/mcp-server"];
          environment = {
            Z_AI_API_KEY = config.sops.placeholder.z_ai_api_key;
            Z_AI_MODE = "ZAI";
          };
        };
        web-search-prime = {
          type = "remote";
          url = "https://api.z.ai/api/mcp/web_search_prime/mcp";
          headers = {
            Authorization = "Bearer ${config.sops.placeholder.z_ai_api_key}";
          };
        };
        web-reader = {
          type = "remote";
          url = "https://api.z.ai/api/mcp/web_reader/mcp";
          headers = {
            Authorization = "Bearer ${config.sops.placeholder.z_ai_api_key}";
          };
        };
        zread = {
          type = "remote";
          url = "https://api.z.ai/api/mcp/zread/mcp";
          headers = {
            Authorization = "Bearer ${config.sops.placeholder.z_ai_api_key}";
          };
        };
      };
    };
  };

  xdg.configFile."opencode/config.json".source =
    config.lib.file.mkOutOfStoreSymlink config.sops.templates."opencode.json".path;
}
