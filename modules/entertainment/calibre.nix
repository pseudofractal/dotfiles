{
  config,
  lib,
  pkgs,
  ...
}: let
  libgenDownloader = pkgs.fetchurl {
    url = "https://github.com/7sarus/calibre-lib/releases/download/v1.70b/libgen_downloader.zip";
    hash = "sha256-SuDGQSdFFvcmOqGarRuRQaXZaFvc8t+SurJL1JSZS6M=";
  };
in {
  home.packages = [
    (config.dotfiles.graphical.nixgl.maybeWrap {
      package = pkgs.calibre;
      bin = "calibre";
    })
  ];

  home.activation.installCalibreLibgen = lib.hm.dag.entryAfter ["writeBoundary"] ''
    run ${lib.getExe' pkgs.calibre "calibre-customize"} -a ${libgenDownloader}
  '';
}
