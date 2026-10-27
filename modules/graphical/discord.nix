{
  config,
  pkgs,
  ...
}: {
  catppuccin.vesktop.enable = true;

  home.packages = [
    # keep-sorted start
    pkgs.concord-tui
    # Concord plays video/audio attachments (media_playback above) via an
    # external mpv on PATH, so it must be installed alongside it.
    pkgs.mpv
    # keep-sorted end
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
      minimizeToTray = false;
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

  xdg.configFile = {
    "concord/config.toml".text = ''
      # Never put the token here, the store is world-readable.
      # Log in once with CONCORD_TOKEN="..." concord and let the
      # keychain remember it, or keep exporting it per launch.
      [credentials]
      store = "auto"

      [display]
      media_playback = true
      show_avatars = true
      show_images = true

      [notifications]
      desktop_notifications = true

      [voice]
      allow_microphone_transmit = true
      push_to_talk = false
      push_to_talk_shortcut = "F8"
      noise_suppression = true
      microphone_sensitivity = -30
      microphone_volume = 100
      voice_output_volume = 100
    '';
  };

  xdg.dataFile = {
    "applications/concord.desktop".text = ''
      [Desktop Entry]
      Name=concord
      Comment=Discord TUI client
      Exec=kitty --app-id=concord concord
      Icon=concord
      Terminal=false
      Type=Application
      Categories=Network;Chat;
      StartupWMClass=concord
    '';
  };
}
