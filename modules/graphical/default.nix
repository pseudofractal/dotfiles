{
  lib,
  pkgs,
  ...
}: {
  options.dotfiles.graphical.nixgl = {
    enable = lib.mkEnableOption "nixGL wrapping for graphical packages";

    package = lib.mkOption {
      type = lib.types.str;
      default = "nixGLDefault";
      example = "nixGLIntel";
      description = "Attribute name under inputs.nixgl.packages.<system> used for wrapping.";
    };
  };

  imports = [
    # keep-sorted start
    ./carta.nix
    ./kitty.nix
    ./nixgl.nix
    ./sioyek.nix
    ./tools.nix
    ./vesktop.nix
    ./vivaldi.nix
    ./zen-browser
    ./zotero.nix
    ./zoom.nix
    # keep-sorted end
  ];
}
