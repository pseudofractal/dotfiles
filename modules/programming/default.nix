{
  lib,
  pkgs,
  inputs,
  ...
}: let
  jetlsRevision = "2026-09-01";
  treefmtEval = inputs.treefmt-nix.lib.evalModule pkgs ../../treefmt.nix;
  runicfmt = pkgs.writeShellScriptBin "runicfmt" ''
    exec ${pkgs.julia}/bin/julia --project="~/.julia/environments/apps/Runic" -e '
      using Runic
      exit(Runic.main(vcat(["--inplace"], ARGS)))
    ' "$@"
  '';
  jetls = pkgs.writeShellScriptBin "jetls" ''
    exec "$HOME/.julia/bin/jetls" "$@"
  '';
in {
  home.sessionVariables.TREEFMT_NO_CACHE = "true";

  home.activation.updateJetls = lib.hm.dag.entryAfter ["writeBoundary"] ''
    jetls_app="$HOME/.julia/bin/jetls"
    jetls_project="$HOME/.julia/environments/apps/JETLS"

    if [ -x "$jetls_app" ] && "$jetls_app" version 2>/dev/null | grep -qF "jetls version ${jetlsRevision},"; then
      echo "info: JETLS ${jetlsRevision} is already installed"
    else
      echo "info: updating JETLS to ${jetlsRevision}"
      if JULIA_LOAD_PATH="@:@stdlib" ${lib.getExe pkgs.julia} \
        --startup-file=no \
        --project="$jetls_project" \
        -e 'using Pkg; Pkg.Apps.add(; url="https://github.com/aviatesk/JETLS.jl", rev="${jetlsRevision}")'; then
        echo "info: JETLS ${jetlsRevision} installed"
      else
        echo "warning: failed to update JETLS; keeping the existing installation"
      fi
    fi
  '';

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
    jetls
    numbat
    runicfmt
    treefmtEval.config.build.wrapper
    # keep-sorted end
  ];
}
