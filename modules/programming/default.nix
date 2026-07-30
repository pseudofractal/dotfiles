{
  pkgs,
  inputs,
  ...
}: let
  treefmtEval = inputs.treefmt-nix.lib.evalModule pkgs ../../treefmt.nix;
  runicfmt = pkgs.writeShellScriptBin "runicfmt" ''
    exec ${pkgs.julia}/bin/julia --project="~/.julia/environments/apps/Runic" -e '
      using Runic
      exit(Runic.main(vcat(["--inplace"], ARGS)))
    ' "$@"
  '';
in {
  imports = [
    # keep-sorted start
    ./nvim
    ./opencode
    ./zed.nix
    # keep-sorted end
  ];
  home.packages = with pkgs; [
    # keep-sorted start
    devenv
    runicfmt
    numbat
    treefmtEval.config.build.wrapper
    # keep-sorted end
  ];
}
