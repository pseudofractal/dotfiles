{
  config,
  lib,
  pkgs,
  ...
}: let
  arxivMcpSrc = pkgs.fetchFromGitHub {
    owner = "takashiishida";
    repo = "arxiv-latex-mcp";
    rev = "HEAD";
    hash = "sha256-kPUCATcZlspS7vl5EiFh18MDvlftMQFi90LXIxjmgbo=";
  };
in {
  programs.opencode.settings.mcp = {
    context7 = {
      type = "remote";
      url = "https://mcp.context7.com/mcp";
    };
    playwright = {
      type = "local";
      command = ["npx" "-y" "@playwright/mcp@latest" "--isolated" "--headless"];
    };
    arxiv = {
      type = "local";
      command = [
        "env"
        "UV_PROJECT_ENVIRONMENT=${config.home.homeDirectory}/.cache/uv-venvs/arxiv_mcp"
        "uv"
        "run"
        "--directory"
        "${arxivMcpSrc}"
        "server/main.py"
      ];
    };
  };
}
