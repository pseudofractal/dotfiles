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
    launcherWrapper ? false,
  }: let
    programName = getProgramName package bin;
    programExecutable = lib.getExe' package programName;
  in
    pkgs.symlinkJoin {
      name = "${lib.getName package}-nixgl";
      meta.mainProgram = programName;

      paths = [package];

      nativeBuildInputs = [
        pkgs.makeWrapper
      ];

      postBuild = ''
        rm -f "$out/bin/${programName}"
        # Prevent ambient host/NVIDIA state from replacing nixGL's Mesa stack.
        wrapperArgs=(
          --unset LD_LIBRARY_PATH
          --unset __GLX_VENDOR_LIBRARY_NAME
          --unset __NV_PRIME_RENDER_OFFLOAD
          --unset __VK_LAYER_NV_optimus
          --unset VK_LOADER_DRIVERS_SELECT
        )
        ${lib.optionalString launcherWrapper ''
          wrapperArgs+=(--set NIX_LAUNCHER_WRAPPER "$out/bin/${programName}")
        ''}
        makeWrapper ${lib.getExe nixGLPackage} \
          "$out/bin/${programName}" \
          "''${wrapperArgs[@]}" \
          --add-flags ${lib.escapeShellArg programExecutable}
      '';
    };

  maybeWrap = {
    package,
    bin ? null,
    launcherWrapper ? false,
  }: let
    wrappedPackage =
      if nixGLEnabled
      then
        wrapWithNixGL {
          inherit package bin launcherWrapper;
        }
      else package;
  in
    wrappedPackage
    // lib.optionalAttrs (package ? override) {
      override = lib.mirrorFunctionArgs package.override (args:
        maybeWrap {
          package = package.override args;
          inherit bin launcherWrapper;
        });
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
            launcherWrapper = false;
          }

        Set launcherWrapper when generated child launchers must re-enter the
        outer nixGL wrapper.
      '';
    };
  };

  config.dotfiles.graphical.nixgl.maybeWrap = maybeWrap;
}
