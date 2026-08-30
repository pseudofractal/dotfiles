{
  config,
  inputs,
  isNixOS,
  lib,
  pkgs,
  ...
}: let
  cfg = config.dotfiles.graphical.nixgl;

  nixGLEnabled = cfg.enable && !isNixOS;
  system = pkgs.stdenv.hostPlatform.system;

  nixGLPackage = let
    packages = inputs.nixgl.packages.${system};
  in
    if builtins.hasAttr cfg.package packages
    then builtins.getAttr cfg.package packages
    else
      throw ''
        dotfiles.graphical.nixgl.package "${cfg.package}"
        is not available for system "${system}".
      '';

  getProgramName = package: bin:
    if bin != null
    then bin
    else package.meta.mainProgram or (lib.getName package);

  wrapWithNixGL = {
    package,
    bin ? null,
  }: let
    programName = getProgramName package bin;
    programExecutable = lib.getExe' package programName;
    programLauncher = pkgs.writeShellScript "${programName}-nixgl-launcher" ''
      if [ "''${__GLX_VENDOR_LIBRARY_NAME:-}" = "nvidia" ] || [ "''${__NV_PRIME_RENDER_OFFLOAD:-}" = "1" ]; then
        unset GBM_BACKENDS_PATH
        unset LIBGL_DRIVERS_PATH
        unset LIBVA_DRIVERS_PATH
        unset __EGL_VENDOR_LIBRARY_FILENAMES
        export LD_LIBRARY_PATH="''${LD_LIBRARY_PATH:+$LD_LIBRARY_PATH:}/usr/lib:/usr/lib64"
      fi
      exec ${programExecutable} "$@"
    '';
  in
    pkgs.symlinkJoin {
      name = "${lib.getName package}-nixgl";

      paths = [package];

      nativeBuildInputs = [
        pkgs.makeWrapper
      ];

      postBuild = ''
        rm -f "$out/bin/${programName}"
        makeWrapper ${lib.getExe nixGLPackage} \
          "$out/bin/${programName}" \
          --add-flags ${lib.escapeShellArg programLauncher}
      '';
    };

  maybeWrap = {
    package,
    bin ? null,
  }: let
    wrappedPackage =
      if nixGLEnabled
      then
        wrapWithNixGL {
          inherit package bin;
        }
      else package;
  in
    wrappedPackage
    // lib.optionalAttrs (package ? override) {
      override = args:
        maybeWrap {
          package = package.override args;
          inherit bin;
        };
    };
in {
  options.dotfiles.graphical.nixgl = {
    enable = lib.mkEnableOption "Wrap graphical applications with nixGL on non-NixOS hosts";

    package = lib.mkOption {
      type = lib.types.str;
      default = "nixGLDefault";
      example = "nixGLNvidia";
      description = ''
        Attribute under inputs.nixgl.packages.<system> used to wrap
        graphical applications.
      '';
    };

    maybeWrap = lib.mkOption {
      type = lib.types.raw;
      readOnly = true;
      description = ''
        Conditionally wraps a package with nixGL.

        Example:

          config.dotfiles.graphical.nixgl.maybeWrap {
            package = pkgs.sioyek;
            bin = "sioyek";
          }
      '';
    };
  };

  config.dotfiles.graphical.nixgl.maybeWrap = maybeWrap;
}
