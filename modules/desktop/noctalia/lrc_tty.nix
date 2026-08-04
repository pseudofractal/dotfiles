{
  lib,
  pkgs,
  ...
}: let
  lrcTty = pkgs.stdenv.mkDerivation {
    pname = "lrc_tty";
    version = "0.6";

    src = pkgs.fetchFromGitHub {
      owner = "larsgrah";
      repo = "lrc_tty";
      rev = "74335ab3302ba5e1fc8672fa9d1d1b466d63d924";
      hash = "sha256-UMaE0Ke6Izr615BzLqhiFM8A6QDu5SUSXFEotqoMRLk=";
    };

    nativeBuildInputs = [
      pkgs.pkg-config
      pkgs.zig_0_15
    ];
    buildInputs = [pkgs.dbus];

    buildPhase = ''
      export ZIG_GLOBAL_CACHE_DIR="$TMPDIR/zig-global-cache"
      zig build -Doptimize=ReleaseSafe
    '';
    checkPhase = ''
      export ZIG_GLOBAL_CACHE_DIR="$TMPDIR/zig-global-cache"
      zig build test
    '';

    installPhase = ''
      install -Dm755 zig-out/bin/lrc_tty "$out/bin/lrc_tty"
    '';

    meta = {
      description = "Terminal lyric viewer for MPRIS-compatible players";
      homepage = "https://github.com/larsgrah/lrc_tty";
      license = lib.licenses.gpl3Only;
      mainProgram = "lrc_tty";
      platforms = lib.platforms.linux;
    };
  };
in {
  home.packages = [
    lrcTty
    pkgs.playerctl
  ];
}
