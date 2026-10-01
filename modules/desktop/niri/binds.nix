{
  lib,
  pkgs,
  noctalia,
  niriUtils,
  syncshotRunner,
}: let
  # Bind with a title shown in niri's hotkey overlay.
  app = title: spawn: {
    _props.hotkey-overlay-title = title;
    inherit spawn;
  };
  # Bind usable on the lock screen (media keys, night light).
  locked = spawn: {
    _props.allow-when-locked = true;
    inherit spawn;
  };

  utils = "${niriUtils}/bin/niri-utils";
  syncshot = "${syncshotRunner}/bin/syncshot-runner";

  workspaces = builtins.listToAttrs (
    map (n: {
      name = "Mod+${
        if n == 10
        then "0"
        else toString n
      }";
      value.focus-workspace = n;
    }) (lib.range 1 10)
  );
in
  workspaces
  // {
    "Mod+Escape".close-window = {};
    "Mod+Space".spawn = ["vicinae" "toggle"];
    "Mod+M" = app "Logout" [noctalia "msg" "panel-toggle" "session"];
    "Mod+T" = app "Terminal" ["kitty"];
    "Mod+Shift+E" = app "GUI File Browser" ["thunar"];
    "Mod+E" = app "File Browser" ["kitty" "-o" "confirm_os_close_window=0" "--app-id=yazi" "yazi"];
    "Mod+C" = app "Code Editor" ["kitty" "-o" "confirm_os_close_window=0" "--app-id=neovim"];
    "Mod+B" = app "Zen Browser" ["zen-twilight"];
    "Mod+Shift+B".spawn = ["zen-twilight" "--private-window"];

    "XF86AudioRaiseVolume" = locked [noctalia "msg" "volume-up" "3"];
    "XF86AudioLowerVolume" = locked [noctalia "msg" "volume-down" "3"];
    "XF86AudioMute" = locked [noctalia "msg" "volume-mute"];
    "XF86AudioMicMute" = locked [noctalia "msg" "mic-mute"];
    "XF86MonBrightnessUp" = locked [noctalia "msg" "brightness-up" "current" "5"];
    "XF86MonBrightnessDown" = locked [noctalia "msg" "brightness-down" "current" "5"];
    "XF86Launch3" = app "Toggle Integrated/Hybrid Graphics" [utils "toggle_graphics_mode"];
    "Mod+Shift+N" = locked [noctalia "msg" "nightlight-toggle"];

    "Mod+F6" = app "Screenshot to Clipboard" [utils "screenshot"];
    "Mod+Shift+S" = app "Save Screenshot and Copy" [utils "screenshot_with_file"];
    "Alt+P" = app "Screenshot and Sync To Tab" [syncshot];
    "Alt+Shift+P" = app "Screenshot and Sync To Tab Inverted" [syncshot "true"];

    "Alt+V" = app "Clipboard History" ["vicinae" "vicinae://launch/clipboard/history"];
    "Alt+Shift+C" = {
      _props.hotkey-overlay-title = "Dynamic Screencast";
      spawn-sh = "niri msg action set-dynamic-cast-window --id $(niri msg --json pick-window | ${lib.getExe pkgs.jq} -r '.id')";
    };

    "Alt+Tab".focus-window-down-or-top = {};
    "Mod+P" = {
      _props.hotkey-overlay-title = "Move Window to Next Monitor";
      move-window-to-monitor-next = {};
    };
    "Mod+Up".focus-workspace-up = {};
    "Mod+Down".focus-workspace-down = {};
    "Mod+Left".focus-column-left-or-last = {};
    "Mod+Right".focus-column-right-or-first = {};
    "Mod+Shift+Up".move-window-up-or-to-workspace-up = {};
    "Mod+Shift+Down".move-window-down-or-to-workspace-down = {};
    "Mod+Shift+Left".move-column-left = {};
    "Mod+Shift+Right".move-column-right = {};
    "Mod+Shift+T" = {
      _props.hotkey-overlay-title = "Toggle Window Tabs";
      toggle-column-tabbed-display = {};
    };
    "Mod+BracketLeft" = {
      _props.hotkey-overlay-title = "Consume/Expel Window";
      consume-or-expel-window-left = {};
    };
    "Mod+BracketRight" = {
      _props.hotkey-overlay-title = "Consume/Expel Window";
      consume-or-expel-window-right = {};
    };
    "Mod+Minus" = {
      _props.hotkey-overlay-title = "Decrease Column Width";
      set-column-width = "-10%";
    };
    "Mod+Equal" = {
      _props.hotkey-overlay-title = "Increase Column Width";
      set-column-width = "+10%";
    };
    "Mod+Shift+Minus" = {
      _props.hotkey-overlay-title = "Decrease Window Height";
      set-window-height = "-10%";
    };
    "Mod+Shift+Equal" = {
      _props.hotkey-overlay-title = "Increase Window Height";
      set-window-height = "+10%";
    };
    "Mod+V" = {
      _props.hotkey-overlay-title = "Toggle Window Floating";
      toggle-window-floating = {};
    };
    "Mod+Ctrl+F" = {
      _props.hotkey-overlay-title = "Toggle Fullscreen";
      fullscreen-window = {};
    };
    "Mod+Shift+F" = {
      _props.hotkey-overlay-title = "Toggle Maximize";
      maximize-window-to-edges = {};
    };
    "Mod+F" = {
      _props.hotkey-overlay-title = "Maximize Column";
      maximize-column = {};
    };
  }
