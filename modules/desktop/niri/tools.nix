{pkgs}: let
  catppucinify = pkgs.callPackage ../../../tools/catppucinify.nix {};
in {
  syncshotRunner = pkgs.writeShellApplication {
    name = "syncshot-runner";
    runtimeInputs = [
      # keep-sorted start
      catppucinify
      pkgs.coreutils
      pkgs.grim
      pkgs.imagemagick
      pkgs.slurp
      pkgs.wayfreeze
      pkgs.wl-clipboard
      pkgs.yad
      # keep-sorted end
    ];
    text = builtins.readFile ./scripts/syncshot-runner.sh;
  };

  niriUtils = pkgs.writeShellApplication {
    name = "niri-utils";
    runtimeInputs = [
      # keep-sorted start
      pkgs.coreutils
      pkgs.grim
      pkgs.libnotify
      pkgs.slurp
      pkgs.wayfreeze
      pkgs.wl-clipboard
      # keep-sorted end
    ];
    text = builtins.readFile ./scripts/niri-utils.sh;
  };
}
