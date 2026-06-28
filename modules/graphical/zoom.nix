{
  config,
  pkgs,
  ...
}: let
  nixgl = config.dotfiles.graphical.nixgl;
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
        makeWrapper ${zoomPackage}/bin/$bin "$out/bin/$bin"
      done
    '';
  };
in {
  home.packages = [
    (nixgl.maybeWrap {
      package = wrappedZoomPackage;
      bin = "zoom";
    })
  ];
}
