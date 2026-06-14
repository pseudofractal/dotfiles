{
  config,
  lib,
  pkgs,
  inputs,
  isNixOS,
  ...
}: let
  nixgl = import ./nixgl-helper.nix {
    inherit config lib pkgs inputs isNixOS;
  };
in {
  options.dotfiles.graphical.nixgl.requests = {
    home = lib.mkOption {
      type = lib.types.listOf (
        lib.types.submodule {
          options = {
            package = lib.mkOption {
              type = lib.types.raw;
            };
            bin = lib.mkOption {
              type = lib.types.nullOr lib.types.str;
              default = null;
            };
          };
        }
      );
      default = [];
    };
  };

  config = let
    cfg = config.dotfiles.graphical.nixgl;
  in {
    home.packages =
      map
      (req:
        nixgl.maybeWrap {
          package = req.package;
          bin = req.bin;
        })
      cfg.requests.home;
  };
}
