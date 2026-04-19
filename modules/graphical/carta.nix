{
  pkgs,
  lib,
  config,
  ...
}: let
  version = "5.1.0";
  system = pkgs.stdenv.hostPlatform.system;

  appImageAsset =
    if system == "x86_64-linux"
    then "carta.AppImage.x86_64.tgz"
    else if system == "aarch64-linux"
    then "carta.AppImage.aarch64.tgz"
    else throw "CARTA AppImage is only supported on Linux x86_64/aarch64 (got ${system})";

  appImageHash =
    if system == "x86_64-linux"
    then "sha256-ugbTLp/W4Qe/vknSFNZ66oTFQWzlrzC0oMU7Z/wyRSk="
    else "sha256-KysFhM9FkzfrbofD5PfJRtYn/JUonP57aHUA2LhIbJo=";

  cartaTarball = pkgs.fetchurl {
    url = "https://github.com/CARTAvis/carta/releases/download/v${version}/${appImageAsset}";
    hash = appImageHash;
  };

  cartaAppImage = pkgs.runCommand "carta-appimage-${version}" {
    nativeBuildInputs = [pkgs.gnutar];
  } ''
    mkdir -p "$out/bin"
    tar -xzf ${cartaTarball}

    appimage_file="$(echo ./*.AppImage)"
    if [ ! -f "$appimage_file" ]; then
      echo "expected one AppImage in CARTA tarball, found none"
      exit 1
    fi

    install -m755 "$appimage_file" "$out/bin/carta.AppImage"
  '';

  cartaLauncher = pkgs.writeShellScriptBin "carta" ''
    browser_cmd="xdg-open CARTA_URL"
    if command -v zen-twilight >/dev/null 2>&1; then
      browser_cmd="zen-twilight CARTA_URL"
    fi

    export PATH=${pkgs.hostname}/bin:$PATH
    export APPIMAGE_EXTRACT_AND_RUN=1

    exec ${cartaAppImage}/bin/carta.AppImage --browser "$browser_cmd" "$@"
  '';

  cartaDesktop = pkgs.makeDesktopItem {
    name = "carta";
    desktopName = "CARTA";
    comment = "Cube Analysis and Rendering Tool for Astronomy";
    exec = "carta %F";
    terminal = false;
    categories = [
      "Science"
      "Astronomy"
    ];
  };

  cartaPackage = pkgs.symlinkJoin {
    name = "carta-${version}";
    paths = [
      cartaLauncher
      cartaDesktop
    ];
    meta = with lib; {
      description = "CARTA astronomy cube viewer launcher";
      platforms = platforms.linux;
      mainProgram = "carta";
    };
  };
in {
  dotfiles.graphical.nixgl.requests.home = [
    {
      package = cartaPackage;
      bin = "carta";
    }
  ];
}
