{
  config,
  pkgs,
  inputs,
  lib,
  ...
}: let
  system = pkgs.stdenv.hostPlatform.system;
  rawPackage = inputs.vicinae.packages.${system}.with-soulver or inputs.vicinae.packages.${system}.default;
  extSrc = name: inputs.vicinae-extensions + "/extensions/${name}";
  mkExtFrom = src: name: let
    pkg = builtins.fromJSON (builtins.readFile (src + "/package.json"));
  in
    inputs.vicinae.lib.${system}.mkVicinaeExtension {
      inherit src;
      pname = name;
      version = pkg.version or "0";
    };
  mkExt = name: mkExtFrom (extSrc name) name;
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
      environment = {
        # The screen-mirror extension shells out to bare wl-mirror/wlr-randr
        # (plus which/ps) with no path preferences, and the daemon unit sets
        # no PATH of its own. Include the Home Manager profile so desktop
        # entries using bare executable names can launch managed apps.
        PATH = "${lib.makeBinPath [pkgs.wl-mirror pkgs.wlr-randr pkgs.grim pkgs.slurp pkgs.imagemagick]}:${config.home.profileDirectory}/bin:/usr/local/bin:/usr/bin:/bin:/usr/local/sbin:/usr/sbin:/sbin";
      };
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
        "screen-mirror"
      ]
      ++ [
        (raycastExt {
          name = "google-translate";
          rev = "d2edae5a5babf0f8f714071f9cab9cc8e5e590bb";
          hash = "sha256-CskrY0L1kQBEFcFjkTsncr1RxTVqWou7kfSk+GU66cg=";
        })
        (mkExtFrom inputs.vicinae-color-picker "color-picker")
      ];

    settings = {
      close_on_focus_loss = true;
      # Keep Bitwarden resolution independent of the service PATH.
      providers."@bl4zee1g/bitwarden".preferences.rbwPath = lib.getExe pkgs.rbw;
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
