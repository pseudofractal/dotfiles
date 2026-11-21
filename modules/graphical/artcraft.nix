{
  config,
  inputs,
  pkgs,
  ...
}: let
  artcraftPkgs = inputs.artcraft.packages.${pkgs.stdenv.hostPlatform.system};

  # The official Craft App lineup from https://getartcraft.com/apps. The same
  # flake also carries the community apps bimcraft, fieldcraft, mailcraft and
  # solidcraft, which are deliberately left out here.
  appNames = [
    "anicraft"
    "cadcraft"
    "craft-anything"
    "deckcraft"
    "designcraft"
    "effectcraft"
    "figcraft"
    "filmcraft"
    "gridcraft"
    "lightcraft"
    "materialcraft"
    "pdfcraft"
    "photocraft"
    "soundcraft"
    "texturecraft"
    "vectorcraft"
    "wordcraft"
  ];
in {
  home.packages = map (name:
    config.dotfiles.graphical.nixgl.maybeWrap {
      package = artcraftPkgs.${name};
      bin = name;
    })
  appNames;
}
