{
  pkgs,
  inputs,
  ...
}: let
  treefmtEval = inputs.treefmt-nix.lib.evalModule pkgs ../../treefmt.nix;
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
    numbat
    treefmtEval.config.build.wrapper
    # keep-sorted end
  ];
}
