{pkgs}: let
  catppucinify = pkgs.callPackage ../../../tools/catppucinify.nix {};
in {
  syncshotRunner = pkgs.writeShellApplication {
    name = "syncshot-runner";
    runtimeInputs = [
      catppucinify
      pkgs.coreutils
      pkgs.grim
      pkgs.imagemagick
      pkgs.slurp
      pkgs.wayfreeze
      pkgs.wl-clipboard
      pkgs.yad
    ];
    text = builtins.readFile ./scripts/syncshot-runner.sh;
  };

  niriUtils = pkgs.writeShellApplication {
    name = "niri-utils";
    runtimeInputs = [
      pkgs.coreutils
      pkgs.grim
      pkgs.libnotify
      pkgs.slurp
      pkgs.wayfreeze
      pkgs.wl-clipboard
    ];
    text = builtins.readFile ./scripts/niri-utils.sh;
  };
}
