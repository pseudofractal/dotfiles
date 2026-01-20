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
      else if (lib.getName pkg) == "zoom-us"
      then "zoom"
      else (pkg.meta.mainProgram or (lib.getName pkg));

    binPath = "${pkg}/bin/${programName}";
  in
    pkgs.writeShellScriptBin programName ''
      export PATH="${pkgs.iproute2}/bin:$PATH"
      export __NV_PRIME_RENDER_OFFLOAD=1
      export __GLX_VENDOR_LIBRARY_NAME=nvidia
      export VK_ICD_FILENAMES=/usr/share/vulkan/icd.d/nvidia_icd.json
      export QT_X11_NO_MITSHM=1
      export _GL_CORE_PROFILE_CHECK=0
      exec ${nixGLPkg}/bin/nixGL ${binPath} "$@"
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
