{
  isAndroid,
  lib,
  ...
}: {
  imports =
    [
      ./mpv.nix
      ./youtube-tui
    ]
    ++ lib.optionals (!isAndroid) [
      ./calibre.nix
      ./movie-import
      ./music.nix
      ./viu.nix
    ];
}
