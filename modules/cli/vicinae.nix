{
  config,
  pkgs,
  inputs,
  ...
}: let
  system = pkgs.stdenv.hostPlatform.system;
  rawPackage = inputs.vicinae.packages.${system}.with-soulver or inputs.vicinae.packages.${system}.default;
  extSrc = name: inputs.vicinae-extensions + "/extensions/${name}";
  mkExt = name: let
    src = extSrc name;
    pkg = builtins.fromJSON (builtins.readFile (src + "/package.json"));
  in
    inputs.vicinae.lib.${system}.mkVicinaeExtension {
      inherit src;
      pname = name;
      version = pkg.version or "0";
    };
  raycastExt = {
    name,
    rev,
    hash,
  }:
    inputs.vicinae.lib.${system}.mkRayCastExtension {
      inherit name rev hash;
    };
in {
  programs.vicinae = {
    enable = true;
    package = config.dotfiles.graphical.nixgl.maybeWrap {
      package = rawPackage;
      bin = "vicinae";
    };
    systemd = {
      enable = true;
      autoStart = true;
    };
    extensions =
      map mkExt [
        "process-manager"
        "niri"
        "nix"
        "github"
        "wiktionary"
        "kaomojis"
        "bitwarden"
      ]
      ++ [
        (raycastExt {
          name = "google-translate";
          rev = "d2edae5a5babf0f8f714071f9cab9cc8e5e590bb";
          hash = "sha256-CskrY0L1kQBEFcFjkTsncr1RxTVqWou7kfSk+GU66cg=";
        })
      ];

    settings = {
      close_on_focus_loss = true;
      launcher_window = {
        opacity = 0.95;
        material = "auto";
        size = {
          width = 900;
          height = 600;
        };
      };
      font = {
        normal = {
          family = "Maple Mono NF CN";
          size = 12;
        };
      };
    };
  };
}
