{
  pkgs,
  config,
  ...
}: {
  catppuccin.vesktop.enable = true;

  home.packages = with pkgs; [
    overlayed
  ];

  programs.vesktop = {
    enable = true;
    package = config.dotfiles.graphical.nixgl.maybeWrap {
      package = pkgs.vesktop;
      bin = "vesktop";
    };

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
