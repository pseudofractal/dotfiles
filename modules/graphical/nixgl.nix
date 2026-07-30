{
  config,
  inputs,
  isNixOS,
  lib,
  pkgs,
  ...
}: let
  cfg = config.dotfiles.graphical.nixgl;

  enabled = cfg.enable && !isNixOS;
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

  executableName = package: bin:
    if bin != null
    then bin
    else package.meta.mainProgram or (lib.getName package);

  wrapPackage = {
    package,
    bin ? null,
  }: let
    program = executableName package bin;
    executable = lib.getExe' package program;
  in
    pkgs.symlinkJoin {
      name = "${lib.getName package}-nixgl";

      paths = [package];

      nativeBuildInputs = [
        pkgs.makeWrapper
      ];

      # postBuild = ''
      #   rm -f "$out/bin/${program}"
      #
      #   makeWrapper ${lib.getExe' nixGLPackage "nixGL"} \
      #     "$out/bin/${program}" \
      #     --add-flags "${executable}"
      # '';
      postBuild = ''
          rm -f "$out/bin/${program}"

          cat > "$out/bin/${program}" <<EOF
        #!${pkgs.runtimeShell}
        echo "LD_LIBRARY_PATH=\$LD_LIBRARY_PATH" >&2
        exec ${lib.getExe' nixGLPackage "nixGL"} ${executable} "\$@"
        EOF

          chmod +x "$out/bin/${program}"
      '';
    };

  maybeWrap = {
    package,
    bin ? null,
  }: let
    wrapped =
      if enabled
      then
        wrapPackage {
          inherit package bin;
        }
      else package;
  in
    wrapped
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
