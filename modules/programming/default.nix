{
  lib,
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
  jetls = pkgs.writeShellScriptBin "jetls" ''
    exec "$HOME/.julia/bin/jetls" "$@"
  '';
in {
  home.sessionVariables = {
    JETLS_JULIA_CMD = lib.getExe pkgs.julia;
    JUPYTER = lib.getExe pkgs.jupyter;
    TREEFMT_NO_CACHE = "true";
  };

  home.activation.updateJetls = lib.hm.dag.entryAfter ["writeBoundary"] ''
    jetls_project="$HOME/.julia/environments/apps/JETLS"

    echo "info: updating JETLS to the latest upstream release"
    if JULIA_LOAD_PATH="@:@stdlib" ${lib.getExe pkgs.julia} \
      --startup-file=no \
      --project="$jetls_project" \
      -e 'using Pkg; Pkg.Apps.add(; url="https://github.com/aviatesk/JETLS.jl", rev="release")'; then
      echo "info: JETLS is up to date with the latest upstream release"
    else
      echo "warning: failed to update JETLS; keeping the existing installation"
    fi
  '';

  home.activation.installDebugAdapter = lib.hm.dag.entryAfter ["writeBoundary"] ''
    debug_adapter_project="$HOME/.julia/environments/apps/DebugAdapter"

    if test ! -f "$debug_adapter_project/Project.toml"; then
      mkdir -p "$debug_adapter_project"
      if ! JULIA_LOAD_PATH="@:@stdlib" ${lib.getExe pkgs.julia} \
        --startup-file=no \
        --project="$debug_adapter_project" \
        -e 'using Pkg; Pkg.add(PackageSpec(url="https://github.com/julia-vscode/DebugAdapter.jl"))'; then
        echo "warning: failed to install Julia DebugAdapter; keeping the existing environment"
      fi
    else
      if ! JULIA_LOAD_PATH="@:@stdlib" ${lib.getExe pkgs.julia} \
        --startup-file=no \
        --project="$debug_adapter_project" \
        -e 'using Pkg; Pkg.instantiate()'; then
        echo "warning: failed to instantiate Julia DebugAdapter; keeping the existing environment"
      fi
    fi
  '';

  imports = [
    # keep-sorted start
    ./claude-code.nix
    ./codex.nix
    ./copilot-cli.nix
    ./nvim
    ./opencode
    ./shared
    ./t3code.nix
    ./typesetting.nix
    ./zed.nix
    # keep-sorted end
  ];
  home.packages = with pkgs; [
    # keep-sorted start
    devenv
    elan
    jetls
    (lib.lowPrio jupyter)
    numbat
    runicfmt
    treefmtEval.config.build.wrapper
    # keep-sorted end
  ];
}
