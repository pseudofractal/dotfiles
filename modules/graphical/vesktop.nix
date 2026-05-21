{
  pkgs,
  lib,
  config,
  inputs,
  isNixOS,
  ...
}: let
  nixgl = import ./nixgl-helper.nix {
    inherit config lib pkgs inputs isNixOS;
  };

  wrappedVesktopPackage = let
    wrap = pkg:
      nixgl.maybeWrap {
        package = pkg;
        bin = "vesktop";
      };
    base = pkgs.vesktop;
  in
    (wrap base)
    // {
      override = args: wrap (base.override args);
    };
in {
  catppuccin.vesktop.enable = true;

  programs.vesktop = {
    enable = true;
    package = wrappedVesktopPackage;

    settings = {
      arRPC = true;
      checkUpdates = false;
      minimizeToTray = true;
    };

    vencord = {
      useSystem = true;
      settings = {
        autoUpdate = false;
        autoUpdateNotification = false;
        notifyAboutUpdates = false;
        plugins = {
          # keep-sorted start
          BetterSessions.enabled = true;
          ClearURLs.enabled = true;
          ImageZoom.enabled = true;
          NoTrack.enabled = true;
          PlatformIndicators.enabled = true;
          ShikiCodeblocks.enabled = true;
          # keep-sorted end
        };
      };
    };
  };
}
