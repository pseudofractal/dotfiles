{
  lib,
  pkgs,
  ...
}: let
  webpOpen = pkgs.writeShellApplication {
    name = "webp-open";
    runtimeInputs = with pkgs; [gnugrep imv libwebp mpv];
    text = ''
      if (( $# == 0 )); then
        echo "usage: webp-open FILE..." >&2
        exit 64
      fi

      if webpinfo -summary "$1" 2>&1 | grep -q 'Animation: 1'; then
        exec mpv "$@"
      else
        exec imv "$@"
      fi
    '';
  };
in {
  imports = [
    # keep-sorted start
    ./catppucinify.nix
    ./kensaku.nix
    ./make-print-ready.nix
    ./mnemosyne.nix
    ./pandoc.nix
    # keep-sorted end
  ];

  home.packages = with pkgs; [
    # keep-sorted start
    imv
    mpv
    # keep-sorted end
  ];

  xdg.dataFile."applications/neovim.desktop".text = ''
    [Desktop Entry]
    Name=Neovim
    TryExec=${pkgs.neovim}/bin/nvim
    Exec=${pkgs.neovim}/bin/nvim -- %F
    Terminal=true
    Type=Application
    NoDisplay=true
    Categories=Utility;TextEditor;
    MimeType=text/plain;text/markdown;text/x-c;text/x-c++src;text/x-python;text/x-rust;text/x-shellscript;text/css;text/csv;text/xml;application/json;application/javascript;application/x-yaml;application/toml;
  '';

  xdg.dataFile."applications/webp-open.desktop".text = ''
    [Desktop Entry]
    Name=WebP Viewer
    Exec=${lib.getExe webpOpen} %F
    Terminal=false
    Type=Application
    NoDisplay=true
    MimeType=image/webp;
  '';

  xdg.mimeApps = {
    enable = true;
    defaultApplications = {
      "application/csv" = ["neovim.desktop"];
      "application/epub+zip" = ["okularApplication_epub.desktop"];
      "application/fits" = ["org.siril.Siril.desktop"];
      "application/illustrator" = ["org.inkscape.Inkscape.desktop"];
      "application/javascript" = ["neovim.desktop"];
      "application/json" = ["neovim.desktop"];
      "application/mathml+xml" = ["math.desktop"];
      "application/msword" = ["writer.desktop"];
      "application/ogg" = ["mpv.desktop"];
      "application/postscript" = ["org.inkscape.Inkscape.desktop"];
      "application/rtf" = ["writer.desktop"];
      "application/tab-separated-values" = ["neovim.desktop"];
      "application/toml" = ["neovim.desktop"];
      "application/vnd.apple.keynote" = ["impress.desktop"];
      "application/vnd.apple.numbers" = ["calc.desktop"];
      "application/vnd.apple.pages" = ["writer.desktop"];
      "application/vnd.corel-draw" = ["org.inkscape.Inkscape.desktop"];
      "application/vnd.ms-excel" = ["calc.desktop"];
      "application/vnd.ms-excel.sheet.binary.macroEnabled.12" = ["calc.desktop"];
      "application/vnd.ms-excel.sheet.macroEnabled.12" = ["calc.desktop"];
      "application/vnd.ms-excel.template.macroEnabled.12" = ["calc.desktop"];
      "application/vnd.ms-powerpoint" = ["impress.desktop"];
      "application/vnd.ms-powerpoint.presentation.macroEnabled.12" = ["impress.desktop"];
      "application/vnd.ms-powerpoint.slideshow.macroEnabled.12" = ["impress.desktop"];
      "application/vnd.ms-powerpoint.template.macroEnabled.12" = ["impress.desktop"];
      "application/vnd.ms-word" = ["writer.desktop"];
      "application/vnd.ms-word.document.macroEnabled.12" = ["writer.desktop"];
      "application/vnd.ms-word.template.macroEnabled.12" = ["writer.desktop"];
      "application/vnd.oasis.opendocument.formula" = ["math.desktop"];
      "application/vnd.oasis.opendocument.formula-template" = ["math.desktop"];
      "application/vnd.oasis.opendocument.graphics" = ["draw.desktop"];
      "application/vnd.oasis.opendocument.presentation" = ["impress.desktop"];
      "application/vnd.oasis.opendocument.presentation-flat-xml" = ["impress.desktop"];
      "application/vnd.oasis.opendocument.spreadsheet" = ["calc.desktop"];
      "application/vnd.oasis.opendocument.spreadsheet-flat-xml" = ["calc.desktop"];
      "application/vnd.oasis.opendocument.text" = ["writer.desktop"];
      "application/vnd.oasis.opendocument.text-flat-xml" = ["writer.desktop"];
      "application/vnd.oasis.opendocument.text-master" = ["writer.desktop"];
      "application/vnd.oasis.opendocument.text-template" = ["writer.desktop"];
      "application/vnd.openxmlformats-officedocument.presentationml.presentation" = ["impress.desktop"];
      "application/vnd.openxmlformats-officedocument.presentationml.slide" = ["impress.desktop"];
      "application/vnd.openxmlformats-officedocument.presentationml.slideshow" = ["impress.desktop"];
      "application/vnd.openxmlformats-officedocument.presentationml.template" = ["impress.desktop"];
      "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet" = ["calc.desktop"];
      "application/vnd.openxmlformats-officedocument.spreadsheetml.template" = ["calc.desktop"];
      "application/vnd.openxmlformats-officedocument.wordprocessingml.document" = ["writer.desktop"];
      "application/vnd.openxmlformats-officedocument.wordprocessingml.template" = ["writer.desktop"];
      "application/vnd.visio" = ["org.inkscape.Inkscape.desktop"];
      "application/x-cb7" = ["okularApplication_comicbook.desktop"];
      "application/x-cbr" = ["okularApplication_comicbook.desktop"];
      "application/x-cbt" = ["okularApplication_comicbook.desktop"];
      "application/x-cbz" = ["okularApplication_comicbook.desktop"];
      "application/x-stellarium-script" = ["org.stellarium.Stellarium.desktop"];
      "application/x-yaml" = ["neovim.desktop"];
      "audio/aac" = ["mpv.desktop"];
      "audio/flac" = ["mpv.desktop"];
      "audio/m4a" = ["mpv.desktop"];
      "audio/mp4" = ["mpv.desktop"];
      "audio/mpeg" = ["mpv.desktop"];
      "audio/ogg" = ["mpv.desktop"];
      "audio/opus" = ["mpv.desktop"];
      "audio/wav" = ["mpv.desktop"];
      "audio/webm" = ["mpv.desktop"];
      "audio/x-matroska" = ["mpv.desktop"];
      "audio/x-m4a" = ["mpv.desktop"];
      "audio/x-wav" = ["mpv.desktop"];
      "audio/x-ms-wma" = ["mpv.desktop"];
      "image/avif" = ["imv.desktop"];
      "image/bmp" = ["imv.desktop"];
      "image/fits" = ["org.siril.Siril.desktop"];
      "image/gif" = ["imv.desktop"];
      "image/heif" = ["imv.desktop"];
      "image/jpeg" = ["imv.desktop"];
      "image/jxl" = ["imv.desktop"];
      "image/png" = ["imv.desktop"];
      "image/svg+xml" = ["imv.desktop"];
      "image/tiff" = ["imv.desktop"];
      "image/vnd.djvu" = ["okularApplication_djvu.desktop"];
      "image/webp" = ["webp-open.desktop"];
      "image/x-fits" = ["org.siril.Siril.desktop"];
      "image/x-pcx" = ["gimp.desktop"];
      "image/x-psd" = ["gimp.desktop"];
      "image/x-xisf" = ["org.siril.Siril.desktop"];
      "image/x-xcf" = ["gimp.desktop"];
      "inode/directory" = ["yazi.desktop"];
      "text/comma-separated-values" = ["neovim.desktop"];
      "text/csv" = ["neovim.desktop"];
      "text/css" = ["neovim.desktop"];
      "text/markdown" = ["neovim.desktop"];
      "text/plain" = ["neovim.desktop"];
      "text/rtf" = ["writer.desktop"];
      "text/spreadsheet" = ["calc.desktop"];
      "text/tab-separated-values" = ["neovim.desktop"];
      "text/x-comma-separated-values" = ["neovim.desktop"];
      "text/x-csv" = ["neovim.desktop"];
      "text/x-c" = ["neovim.desktop"];
      "text/x-c++src" = ["neovim.desktop"];
      "text/x-python" = ["neovim.desktop"];
      "text/x-rust" = ["neovim.desktop"];
      "text/x-seq" = ["org.siril.Siril.desktop"];
      "text/x-shellscript" = ["neovim.desktop"];
      "text/xml" = ["neovim.desktop"];
      "video/3gpp" = ["mpv.desktop"];
      "video/mpeg" = ["mpv.desktop"];
      "video/mp4" = ["mpv.desktop"];
      "video/ogg" = ["mpv.desktop"];
      "video/quicktime" = ["mpv.desktop"];
      "video/ser" = ["org.siril.Siril.desktop"];
      "video/webm" = ["mpv.desktop"];
      "video/x-flv" = ["mpv.desktop"];
      "video/x-matroska" = ["mpv.desktop"];
      "video/x-msvideo" = ["mpv.desktop"];
      "video/x-ms-wmv" = ["mpv.desktop"];
      "x-scheme-handler/mailto" = ["aerc.desktop"];
      "x-scheme-handler/zotero" = ["zotero.desktop"];
    };
  };
}
