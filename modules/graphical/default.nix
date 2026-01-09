{
  pkgs,
  lib,
  inputs,
  isNixOS,
  ...
} @ args: let
  system = pkgs.stdenv.hostPlatform.system;
  nixGLPkg = inputs.nixgl.packages.${system}.nixGLDefault;
  wrap = pkg: let
    programName =
      if (lib.getName pkg) == "mesa-demos"
      then "glxinfo"
      else (pkg.meta.mainProgram or (lib.getName pkg));

    binPath = "${pkg}/bin/${programName}";
  in
    pkgs.writeShellScriptBin programName ''
      exec ${nixGLPkg}/bin/nixGL* ${binPath} "$@"
    '';

  applyNixGL = modules:
    map (
      path: let
        m = import path args;
        shouldWrap = (m.useNixGL or false) && !isNixOS;
        cleanedModule = builtins.removeAttrs m ["useNixGL"];
      in
        cleanedModule
        // {
          home.packages =
            if shouldWrap
            then map wrap (m.home.packages or [])
            else (m.home.packages or []);
        }
    )
    modules;
in {
  imports = applyNixGL [
    ./packet.nix
    ./zoom.nix
    ./tools.nix
  ];
}
