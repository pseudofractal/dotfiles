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
  home.packages = [pkgs.hyprpicker];

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
        "bitwarden-vault"
      ]
      ++ [
        # For future Raycast extensions.
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
