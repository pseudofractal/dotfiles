{lib, ...}: {
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
    ./nixgl.nix
    ./zoom.nix
    ./zen-browser
    ./tools.nix
    ./sioyek.nix
    ./kitty.nix
    ./vesktop.nix
    ./zotero.nix
    ./carta.nix
  ];
}
