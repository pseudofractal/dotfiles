{
  config,
  isAndroid,
  lib,
  pkgs,
  ...
}: let
  cfg = config.dotfiles.programming.typesetting;

  isKnownTexlivePackage = name: builtins.hasAttr name pkgs.texlive.pkgs;

  partitionedExtraPackages = lib.partition isKnownTexlivePackage cfg.texlive.extraPackages;

  knownExtraPackages = partitionedExtraPackages.right;
  unknownExtraPackages = partitionedExtraPackages.wrong;

  texlive =
    pkgs.texliveSmall.withPackages (ps:
      map (name: ps.${name}) knownExtraPackages);

  typst = pkgs.typst;
in {
  options.dotfiles.programming.typesetting = {
    texlive.extraPackages = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [
        "biber"
        "biblatex"
        "collection-fontsrecommended"
        "collection-latexextra"
        "collection-mathscience"
        "collection-pictures"
        "latexmk"
        "pythontex"
      ];
      example = lib.literalExpression ''
        [
          "collection-fontsextra"
          "collection-langgreek"
        ]
      '';
      description = ''
        Extra TeX Live packages or collections added to `texliveSmall`. The
        default covers common LaTeX packages, mathematics and physics
        tooling, diagrams, bibliography tools, and fonts. Add names from
        `pkgs.texlive.pkgs`, such as `revtex`, `collection-fontsextra`, or
        `collection-langgreek`.
      '';
    };

    packages = {
      typst = lib.mkOption {
        type = lib.types.package;
        readOnly = true;
        description = "Typst compiler shared by document tools.";
      };
      texlive = lib.mkOption {
        type = lib.types.package;
        readOnly = true;
        description = "TeX Live environment shared by document tools.";
      };
    };
  };

  config = {
    assertions = [
      {
        assertion = unknownExtraPackages == [];
        message =
          "Unknown TeX Live package(s) in "
          + "dotfiles.programming.typesetting.texlive.extraPackages: "
          + lib.concatStringsSep ", " unknownExtraPackages;
      }
    ];

    home.packages =
      [typst]
      ++ lib.optional (!isAndroid) texlive;

    dotfiles.programming.typesetting.packages = {inherit texlive typst;};
  };
}
