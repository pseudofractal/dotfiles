{
  pkgs,
  lib,
  ...
}: let
  makePrintReadyRust = pkgs.rustPlatform.buildRustPackage {
    pname = "make-print-ready";
    version = "0.1.0";
    src = ../../tools/make-print-ready-rs;
    cargoLock.lockFile = ../../tools/make-print-ready-rs/Cargo.lock;
    nativeBuildInputs = [pkgs.makeWrapper];
    buildInputs = [pkgs.pdfium-binaries];
    doCheck = false;
    postFixup = ''
      wrapProgram "$out/bin/make-print-ready" \
        --set PDFIUM_DYNAMIC_LIB_PATH "${lib.getLib pkgs.pdfium-binaries}/lib/libpdfium.so"
    '';
    meta = with lib; {
      description = "Convert Catppuccin-themed PDFs into print-friendly black/white outputs";
      mainProgram = "make-print-ready";
      platforms = platforms.linux;
    };
  };
in {
  home.packages = [makePrintReadyRust];
}
