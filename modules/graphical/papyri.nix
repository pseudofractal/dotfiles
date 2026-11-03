{
  config,
  inputs,
  pkgs,
  ...
}: let
  unwrapped = inputs.papyri.packages.${pkgs.stdenv.hostPlatform.system}.default;
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
  home.packages = [papyriWithDesktop];
}
