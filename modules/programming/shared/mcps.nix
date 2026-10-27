{
  config,
  lib,
  pkgs,
  ...
}: let
  arxivMcpSrc = pkgs.fetchFromGitHub {
    owner = "takashiishida";
    repo = "arxiv-latex-mcp";
    rev = "52d89be8e916442032e748fbad8857ac2d9e3f82";
    hash = "sha256-g/UgclS2+u5qqTpTKXauSuMJWZZsrq53XXWigE8kses=";
  };
  arxivMcp = pkgs.writeShellApplication {
    name = "arxiv-latex-mcp";
    runtimeInputs = [pkgs.coreutils pkgs.util-linux pkgs.uv];
    text = ''
      # setuptools writes egg-info alongside the sources even for wheel builds.
      # Give it a writable copy, keyed by the exact Nix source store path.
      cache_home="''${XDG_CACHE_HOME:-}"
      if [ -z "$cache_home" ]; then
        cache_home=${lib.escapeShellArg config.xdg.cacheHome}
      fi
      cache_root="$cache_home/arxiv-latex-mcp/${builtins.baseNameOf arxivMcpSrc}"
      source_dir="$cache_root/source"
      mkdir -p "$cache_root"
      (
        flock -x 9
        if [ ! -d "$source_dir" ]; then
          staging=$(mktemp -d "$cache_root/.source.XXXXXX")
          trap 'rm -rf "$staging"' EXIT
          cp -R --no-preserve=mode ${arxivMcpSrc}/. "$staging/"
          mv "$staging" "$source_dir"
          trap - EXIT
        fi
      ) 9>"$cache_root/prepare.lock"

      export UV_PROJECT_ENVIRONMENT="$cache_root/venv"
      exec uv run --frozen --no-editable \
        --python ${lib.getExe pkgs.python3} \
        --project "$source_dir" arxiv-latex-mcp "$@"
    '';
  };
in {
  programs.mcp = {
    enable = true;
    servers = {
      context7 = {
        url = "https://mcp.context7.com/mcp";
      };
      playwright = {
        command = lib.getExe pkgs.playwright-mcp;
        args = ["--isolated" "--headless"];
      };
      arxiv = {
        command = lib.getExe arxivMcp;
      };
      nix = {
        command = lib.getExe pkgs.mcp-nixos;
      };
    };
  };
}
