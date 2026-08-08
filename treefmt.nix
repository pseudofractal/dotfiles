{pkgs, ...}: let
  runicfmt = pkgs.writeShellScriptBin "runicfmt" ''
    exec ${pkgs.julia}/bin/julia --project="~/.julia/environments/apps/Runic" -e '
      using Runic
      exit(Runic.main(vcat(["--inplace"], ARGS)))
    ' "$@"
  '';
in {
  projectRootFile = ".git/config";
  settings.excludes = ["secrets.yaml"];

  programs = {
    alejandra.enable = true;
    clang-format.enable = true;
    fish_indent.enable = true;
    gofmt.enable = true;
    google-java-format.enable = true;
    keep-sorted.enable = true;
    ktfmt.enable = true;
    shfmt = {
      enable = true;
      indent_size = 2;
    };
    qmlformat.enable = true;
    sql-formatter.enable = true;
    stylua.enable = true;
    texfmt.enable = true;
    biome = {
      enable = true;
      formatCommand = "format";
      # The pinned treefmt-nix schema predates Biome's markup support.
      validate.enable = false;
      includes = [
        "*.astro"
        "*.cjs"
        "*.css"
        "*.cts"
        "*.d.cts"
        "*.d.mts"
        "*.d.ts"
        "*.html"
        "*.js"
        "*.json"
        "*.jsonc"
        "*.jsx"
        "*.mjs"
        "*.mts"
        "*.svelte"
        "*.ts"
        "*.tsx"
        "*.vue"
      ];
      settings = {
        formatter = {
          indentStyle = "space";
          indentWidth = 2;
          lineWidth = 100;
        };
        html = {
          experimentalFullSupportEnabled = true;
          formatter.enabled = true;
        };
        javascript.formatter = {
          quoteStyle = "double";
          semicolons = "asNeeded";
        };
        css.formatter.indentStyle = "space";
      };
    };
    mdformat.enable = true;
    rustfmt.enable = true;
    ruff-format.enable = true;
    taplo.enable = true;
    yamlfmt.enable = true;
    typstyle.enable = true;
  };

  settings.formatter.rustfmt.options = ["--config" "tab_spaces=2"];

  settings.formatter.julia = {
    command = "${runicfmt}/bin/runicfmt";
    options = [];
    includes = ["*.jl"];
  };
}
