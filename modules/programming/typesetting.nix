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

  physketchSource = pkgs.fetchzip {
    url = "https://mirrors.ctan.org/graphics/pgf/contrib/physketch.zip";
    hash = "sha256-BoGP9fKqw3W1YX7pHvnCIlR41VtV4MZPbRqDLM3RduQ=";
  };
  physketchTexmf = pkgs.runCommand "physketch-texmf" {} ''
    mkdir -p "$out"
    cp ${physketchSource}/*.sty "$out/"
  '';

  texlive =
    pkgs.texliveSmall.withPackages (ps:
      map (name: ps.${name}) knownExtraPackages);

  typst = pkgs.typst;
  asymptote = pkgs.asymptote;
in {
  options.dotfiles.programming.typesetting = {
    texlive.extraPackages = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [
        "biber"
        "biblatex"
        "circuitikz"
        "collection-fontsrecommended"
        "collection-latexextra"
        "collection-mathscience"
        "collection-pictures"
        "latexmk"
        "pythontex"
        "tikz-feynhand"
        "tikz-feynman"
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
      asymptote = lib.mkOption {
        type = lib.types.package;
        readOnly = true;
        description = "Asymptote vector graphics compiler.";
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
      ++ lib.optionals (!isAndroid) [texlive asymptote];

    home.file = lib.mkIf (!isAndroid) {
      "texmf/tex/latex/physketch" = {
        source = physketchTexmf;
        recursive = true;
      };
    };

    dotfiles.programming.typesetting.packages = {inherit asymptote texlive typst;};
  };
}
