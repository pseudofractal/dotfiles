{pkgs, ...}: let
  runicfmt = pkgs.writeShellScriptBin "runicfmt" ''
    exec ${pkgs.julia}/bin/julia --project="~/.julia/environments/apps/Runic" -e '
      using Runic
      exit(Runic.main(vcat(["--inplace"], ARGS)))
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
    command = "${runicfmt}/bin/runicfmt";
    options = [];
    includes = ["*.jl"];
  };
}
