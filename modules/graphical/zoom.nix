{pkgs, ...}: let
  zoomPackage = pkgs.zoom-us.override {
    targetPkgs = p: [
      p.iproute2
      p.mesa
      p.xdg-utils
    ];
  };

  wrappedZoomPackage = pkgs.symlinkJoin {
    name = "zoom-browser-fixed";
    paths = [zoomPackage];
    nativeBuildInputs = [pkgs.makeWrapper];
    postBuild = ''
      for bin in zoom zoom-us; do
        rm -f "$out/bin/$bin"
        makeWrapper ${zoomPackage}/bin/$bin "$out/bin/$bin" --set BROWSER ${pkgs.firefox}/bin/firefox
      done
    '';
  };
in {
  home.packages = [wrappedZoomPackage];
}
