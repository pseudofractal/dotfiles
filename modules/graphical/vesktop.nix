{
  pkgs,
  lib,
  config,
  ...
}: let
  wrappedVesktopPackage = let
    wrap = pkg:
      config.dotfiles.graphical.nixgl.maybeWrap {
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

  home.packages = with pkgs; [
    overlayed
  ];

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
