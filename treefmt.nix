{pkgs, ...}: let
  jlfmt = pkgs.writeShellScriptBin "jlfmt" ''
    export JULIA_LOAD_PATH="~/.julia/environments/formatter"
    exec ${pkgs.julia}/bin/julia -e '
      using JuliaFormatter
      exit(JuliaFormatter.main(vcat(["--inplace"], ARGS)))
    ' "$@"
  '';
in {
  projectRootFile = "flake.nix";

  programs = {
    alejandra.enable = true;
    keep-sorted.enable = true;
    shfmt = {
      enable = true;
      indent_size = 2;
    };
    stylua.enable = true;
    biome = {
      enable = true;
      formatCommand = "format";
      settings = {
        formatter = {
          indentStyle = "space";
          indentWidth = 2;
          lineWidth = 100;
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

  settings.formatter.julia = {
    command = "${jlfmt}/bin/jlfmt";
    options = [];
    includes = ["*.jl"];
  };
}
