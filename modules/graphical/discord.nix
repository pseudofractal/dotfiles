{
  config,
  inputs,
  lib,
  pkgs,
  ...
}: let
  concordPackage = inputs.concord.packages.${pkgs.stdenv.hostPlatform.system}.default;

  discordPackage = config.dotfiles.graphical.nixgl.maybeWrap {
    package = pkgs.discord;
    bin = "discord";
  };

  # Seeded once so the Bluetooth output and volumes survive the migration from
  # the old Home Manager-managed config. Concord owns this file afterwards.
  concordConfig = pkgs.writeText "concord-config.toml" ''
    # Seeded once by Home Manager. Concord owns this file after the first run.
    [credentials]
    store = "auto"

    [display]
    media_playback = true
    show_avatars = true
    show_images = true

    [notifications]
    desktop_notifications = true

    [voice]
    self_mute = false
    self_deaf = false
    # BlueZ sink for the earbuds; re-pick it in Voice Options if re-paired.
    output_source = "pulseaudio:bluez_output.41_42_FF_B7_61_D3.1"
    allow_microphone_transmit = true
    push_to_talk = false
    push_to_talk_shortcut = "F8"
    noise_suppression = true
    microphone_sensitivity = -30
    microphone_volume = 105
    voice_output_volume = 168
  '';
in {
  home.activation.concordConfig = lib.hm.dag.entryAfter ["linkGeneration"] ''
    concord_config="${config.xdg.configHome}/concord/config.toml"

    if [ -L "$concord_config" ] || [ ! -e "$concord_config" ]; then
      $DRY_RUN_CMD rm -f "$concord_config"
      $DRY_RUN_CMD install -d -m700 "${config.xdg.configHome}/concord"
      $DRY_RUN_CMD install -m600 ${concordConfig} "$concord_config"
    fi
  '';

  programs.concord = {
    enable = true;
    package = concordPackage;
  };

  programs.discord = {
    enable = true;
    package = discordPackage;
    settings.SKIP_HOST_UPDATE = true;
  };

  xdg.configFile = {
    "concord/keymap.toml".text = ''
      # Arrow-first navigation; Vim keys stay as secondary bindings.
      [keymap]
      SelectNext = ["down", "j"]
      SelectPrevious = ["up", "k"]
      CycleFocusNext = ["right", "tab", "l"]
      CycleFocusPrevious = ["left", "<S-tab>", "h"]
      HalfPageDown = ["<S-down>", "<C-d>"]
      HalfPageUp = ["<S-up>", "<C-u>"]
      ScrollViewportDown = ["<C-down>", "J"]
      ScrollViewportUp = ["<C-up>", "K"]
      ScrollHorizontalLeft = ["<S-left>", "H"]
      ScrollHorizontalRight = ["<S-right>", "L"]
      JumpTop = ["home", "gg"]
      JumpBottom = ["end", "G"]

      ChannelSwitcher = ["<C-k>", "<leader><leader>"]
      OpenNotificationInbox = ["<C-S-i>", "<leader>n"]
      OpenOptions = ["<leader>o", "<C-,>"]
      OpenVoiceOptions = "<leader>vo"
      VoiceMute = ["<C-S-m>", "<leader>vm"]
      VoiceDeafen = ["<C-S-d>", "<leader>vD"]
      OpenPaneFilter = ["/", "<C-f>"]

      # Direct message actions that are menu-only by default.
      ShowMessageProfile = "p"
      PinMessage = "P"
      OpenThread = "t"
      ShowReactionUsers = "u"
      OpenPollVotePicker = "c"
    '';
  };

  xdg.dataFile = {
    "applications/concord.desktop".text = ''
      [Desktop Entry]
      Name=Concord
      GenericName=Discord Client
      Comment=Discord TUI client
      Exec=${lib.getExe' pkgs.kitty "kitty"} --app-id=concord ${lib.getExe' concordPackage "concord"}
      Icon=utilities-terminal
      Terminal=false
      Type=Application
      Categories=Network;Chat;
      Keywords=discord;chat;tui;
      StartupNotify=true
      StartupWMClass=concord
    '';

    "applications/discord.desktop".text = ''
      [Desktop Entry]
      Name=Discord
      GenericName=Instant Messenger
      Comment=All-in-one voice and text chat
      Exec=${lib.getExe' discordPackage "discord"}
      Icon=discord
      Terminal=false
      Type=Application
      Categories=Network;Chat;
      Keywords=discord;chat;voice;
      MimeType=x-scheme-handler/discord;
      StartupNotify=true
      StartupWMClass=discord
    '';
  };
}
