{
  lib,
  pkgs,
  ...
}: {
  imports = [
    # keep-sorted start
    ./carta.nix
    ./kitty.nix
    ./nixgl.nix
    ./packet.nix
    ./prismlauncher.nix
    ./sioyek.nix
    ./tools.nix
    ./vesktop.nix
    ./vivaldi.nix
    ./zen-browser
    ./zoom.nix
    ./zotero.nix
    # keep-sorted end
  ];
}
