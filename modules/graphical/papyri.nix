{
  config,
  inputs,
  lib,
  pkgs,
  ...
}: let
  unwrapped = inputs.papyri.packages.${pkgs.stdenv.hostPlatform.system}.default;

  typesettingPackages = config.dotfiles.programming.typesetting.packages;

  fontFamily = "Maple Mono NF CN";

  papyri = config.dotfiles.graphical.nixgl.maybeWrap {
    package = unwrapped;
    bin = "papyri";
  };

  papyriWithDesktop = pkgs.symlinkJoin {
    name = "papyri-with-desktop";
    paths = [papyri];
    nativeBuildInputs = with pkgs; [
      desktop-file-utils
      gnused
    ];
    postBuild = ''
      desktop="$out/share/applications/papyri.desktop"
      if [ -e "$desktop" ]; then
        rm -f "$desktop"
        cp ${unwrapped}/share/applications/papyri.desktop "$desktop"
        chmod u+w "$desktop"
        sed -i \
          -e "s|^Exec=.*|Exec=$out/bin/papyri %f|" \
          -e "s|^TryExec=.*|TryExec=$out/bin/papyri|" \
          "$desktop"
        desktop-file-validate "$desktop"
      fi
    '';
    meta = unwrapped.meta // {mainProgram = "papyri";};
  };
in {
  programs.papyri = {
    enable = true;
    package = papyriWithDesktop;
    settings = {
      theme = "mocha";

      uiFont = fontFamily;
      textFont = fontFamily;
      codeFont = fontFamily;

      typstPath = lib.getExe typesettingPackages.typst;

      latexEngine = "lualatex";
      latexPaths = {
        lualatex = lib.getExe' typesettingPackages.texlive "lualatex";
        pdflatex = lib.getExe' typesettingPackages.texlive "pdflatex";
        xelatex = lib.getExe' typesettingPackages.texlive "xelatex";
      };

      languageServerPaths = {
        markdown = lib.getExe pkgs.marksman;
        typst = lib.getExe pkgs.tinymist;
        latex = lib.getExe pkgs.texlab;
      };
    };
  };
}
