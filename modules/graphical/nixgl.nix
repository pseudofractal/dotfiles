{
  config,
  lib,
  pkgs,
  inputs,
  isNixOS,
  ...
}: let
  cfg = config.dotfiles.graphical.nixgl;
  enabled = cfg.enable && !isNixOS;
  system = pkgs.stdenv.hostPlatform.system;

  getProgramName = pkg: bin:
    if bin != null
    then bin
    else if (lib.getName pkg) == "mesa-demos"
    then "glxinfo"
    else if (lib.getName pkg) == "zoom-us"
    then "zoom"
    else (pkg.meta.mainProgram or (lib.getName pkg));

  resolveNixGLPkg = let
    nixGLPackages = inputs.nixgl.packages.${system};
  in
    if builtins.hasAttr cfg.package nixGLPackages
    then builtins.getAttr cfg.package nixGLPackages
    else throw "dotfiles.graphical.nixgl.package `${cfg.package}` is not available for `${system}`";

  wrapPackage = nixGLPkg: pkg: bin: let
    programName = getProgramName pkg bin;
    binPath = "${pkg}/bin/${programName}";
  in
    pkgs.symlinkJoin {
      name = "${lib.getName pkg}-nixgl";
      paths = [pkg];
      nativeBuildInputs = [pkgs.makeWrapper];
      postBuild = ''
        rm -f $out/bin/${programName}
        makeWrapper ${lib.getExe' nixGLPkg "nixGL"} $out/bin/${programName} --add-flags ${binPath}
      '';
    };

  maybeWrap = {
    package,
    bin ? null,
  }:
    if enabled
    then wrapPackage resolveNixGLPkg package bin
    else package;
in {
  options.dotfiles.graphical.nixgl = {
    enable = lib.mkEnableOption "nixGL wrapping for graphical packages";

    package = lib.mkOption {
      type = lib.types.str;
      default = "nixGLDefault";
      example = "nixGLIntel";
      description = "Attribute name under inputs.nixgl.packages.<system> used for wrapping.";
    };

    maybeWrap = lib.mkOption {
      type = lib.types.raw;
      readOnly = true;
      description = "Function to conditionally wrap a package with nixGL. Usage: maybeWrap { package = pkgs.foo; bin = \"foo\"; }";
    };
  };

  config.dotfiles.graphical.nixgl.maybeWrap = maybeWrap;
}
