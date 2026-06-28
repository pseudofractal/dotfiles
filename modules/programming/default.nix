{
  pkgs,
  inputs,
  ...
}: let
  treefmtEval = inputs.treefmt-nix.lib.evalModule pkgs ../../treefmt.nix;
  jlfmt = pkgs.writeShellScriptBin "jlfmt" ''
    export JULIA_LOAD_PATH="~/.julia/environments/formatter"
    exec ${pkgs.julia}/bin/julia -e '
      using JuliaFormatter
      exit(JuliaFormatter.main(vcat(["--inplace", "--threads=6"], ARGS)))
    ' "$@"
  '';
in {
  imports = [
    # keep-sorted start
    ./nvf
    ./nvim
    ./opencode
    ./zed.nix
    # keep-sorted end
  ];
  home.packages = with pkgs; [
    # keep-sorted start
    devenv
    jlfmt
    numbat
    treefmtEval.config.build.wrapper
    # keep-sorted end
  ];
}
