{
  config,
  inputs,
  lib,
  pkgs,
  ...
}: let
  noctalia = lib.getExe config.programs.noctalia.package;
  scripts = "${config.xdg.configHome}/niri-nix/scripts";
  system = pkgs.stdenv.hostPlatform.system;
  niriPackages = inputs.niri.packages.${system};

  match = props: {match._props = props;};
in {
  wayland.windowManager.niri = {
    enable = true;
    package = niriPackages.niri-unstable;
    checkConfig = true;
    xwaylandSatellitePackage = niriPackages.xwayland-satellite-unstable;
    portalPackage = pkgs.xdg-desktop-portal-gnome;

    settings = {
      input = {
        keyboard = {
          xkb = {
            layout = "";
            model = "";
            rules = "";
            variant = "";
          };
          repeat-delay = 600;
          repeat-rate = 25;
          track-layout = "global";
        };
        touchpad = {
          tap = {};
          dwt = {};
          natural-scroll = {};
          tap-button-map = "left-right-middle";
          scroll-factor = 0.75;
        };
      };

      prefer-no-csd = {};
      overview.zoom = 0.4;

      layout = {
        gaps = 2;
        struts = {
          left = 0;
          right = 0;
          top = 0;
          bottom = 0;
        };
        border = {
          width = 2;
          active-gradient._props = {
            from = "#33ccffee";
            to = "#00ffffee";
            angle = 45;
          };
          inactive-color = "#595959aa";
        };
        focus-ring.off = {};
        tab-indicator = {
          hide-when-single-tab = {};
          gap = -25;
          width = 15;
          length._props.total-proportion = 0.1;
          position = "top";
          gaps-between-tabs = 4;
          corner-radius = 3;
        };
        default-column-width.proportion = 0.5;
        center-focused-column = "never";
        always-center-single-column = {};
      };

      hotkey-overlay = {
        skip-at-startup = {};
        hide-not-bound = {};
      };

      binds = {
        "Mod+Escape".close-window = {};
        "Mod+Space".spawn = ["vicinae" "toggle"];
        "Mod+M" = {
          _props.hotkey-overlay-title = "Logout";
          spawn = [noctalia "msg" "panel-toggle" "session"];
        };
        "Mod+T" = {
          _props.hotkey-overlay-title = "Terminal";
          spawn = ["kitty"];
        };
        "Mod+Shift+E" = {
          _props.hotkey-overlay-title = "GUI File Browser";
          spawn = ["thunar"];
        };
        "Mod+E" = {
          _props.hotkey-overlay-title = "File Browser";
          spawn = ["kitty" "-o" "confirm_os_close_window=0" "--app-id=yazi" "yazi"];
        };
        "Mod+C" = {
          _props.hotkey-overlay-title = "Code Editor";
          spawn = ["kitty" "-o" "confirm_os_close_window=0" "--app-id=neovim"];
        };
        "Mod+B" = {
          _props.hotkey-overlay-title = "Zen Browser";
          spawn = ["zen-twilight"];
        };
        "Mod+Shift+B".spawn = ["zen-twilight" "--private-window"];

        "XF86AudioRaiseVolume" = {
          _props.allow-when-locked = true;
          spawn = [noctalia "msg" "volume-up" "3"];
        };
        "XF86AudioLowerVolume" = {
          _props.allow-when-locked = true;
          spawn = [noctalia "msg" "volume-down" "3"];
        };
        "XF86AudioMute" = {
          _props.allow-when-locked = true;
          spawn = [noctalia "msg" "volume-mute"];
        };
        "XF86AudioMicMute" = {
          _props.allow-when-locked = true;
          spawn = [noctalia "msg" "mic-mute"];
        };
        "XF86MonBrightnessUp" = {
          _props.allow-when-locked = true;
          spawn = [noctalia "msg" "brightness-up" "current" "5"];
        };
        "XF86MonBrightnessDown" = {
          _props.allow-when-locked = true;
          spawn = [noctalia "msg" "brightness-down" "current" "5"];
        };
        "Mod+Shift+N" = {
          _props.allow-when-locked = true;
          spawn = [noctalia "msg" "nightlight-toggle"];
        };

        "Mod+F6" = {
          _props.hotkey-overlay-title = "Screenshot";
          spawn = ["${scripts}/utils" "screenshot"];
        };
        "Mod+Shift+F6" = {
          _props.hotkey-overlay-title = "Screenshot and Save";
          spawn = ["${scripts}/utils" "screenshot_with_file"];
        };
        "Alt+P" = {
          _props.hotkey-overlay-title = "Screenshot and Sync To Tab";
          spawn = ["${scripts}/syncshot-runner"];
        };
        "Alt+Shift+P" = {
          _props.hotkey-overlay-title = "Screenshot and Sync To Tab Inverted";
          spawn = ["${scripts}/syncshot-runner" "true"];
        };

        "Alt+C" = {
          _props.hotkey-overlay-title = "Color Picker";
          spawn-sh = "zenity --color-selection --title 'Color Picker' --color \"$(hyprpicker -n)\"";
        };
        "Alt+V" = {
          _props.hotkey-overlay-title = "Clipboard History";
          spawn-sh = "cliphist list | wofi -dmenu | cliphist decode | wl-copy";
        };
        "Alt+G" = {
          _props.hotkey-overlay-title = "Gitmojis";
          spawn = ["${scripts}/utils" "handle_gitmoji"];
        };
        "Alt+Shift+C" = {
          _props.hotkey-overlay-title = "Dynamic Screencast";
          spawn-sh = "niri msg action set-dynamic-cast-window --id $(niri msg --json pick-window | jq -r '.id')";
        };

        "Mod+1".focus-workspace = 1;
        "Mod+2".focus-workspace = 2;
        "Mod+3".focus-workspace = 3;
        "Mod+4".focus-workspace = 4;
        "Mod+5".focus-workspace = 5;
        "Mod+6".focus-workspace = 6;
        "Mod+7".focus-workspace = 7;
        "Mod+8".focus-workspace = 8;
        "Mod+9".focus-workspace = 9;
        "Mod+0".focus-workspace = 10;
        "Alt+Tab".focus-window-down-or-top = {};
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
      };

      animations = {
        exit-confirmation-open-close.off = {};
        window-close = {
          duration-ms = 250;
          curve = "ease-out-quad";
        };
        window-open = {
          duration-ms = 250;
          curve = "ease-out-expo";
        };
      };

      cursor = {
        xcursor-theme = "elementary";
        xcursor-size = 25;
      };

      _children = [
        {spawn-at-startup = [noctalia "--daemon"];}
        {spawn-at-startup = [(lib.getExe' pkgs.blueman "blueman-applet")];}
        {spawn-at-startup = [(lib.getExe' pkgs.networkmanagerapplet "nm-applet") "--indicator"];}

        {
          output = {
            _args = ["eDP-1"];
            scale = 1;
            transform = "normal";
            mode = "1920x1200@60.003";
          };
        }

        {workspace._args = ["Work"];}
        {workspace._args = ["Utilities"];}
        {workspace._args = ["Entertainment"];}

        {
          window-rule = {
            geometry-corner-radius = [12.0 12.0 12.0 12.0];
            clip-to-geometry = true;
          };
        }
        {
          window-rule._children = [
            (match {is-window-cast-target = true;})
            {
              border = {
                on = {};
                width = 5;
                active-color = "#d20f39";
              };
            }
            {focus-ring.off = {};}
            {
              shadow = {
                on = {};
                color = "#d20f3970";
              };
            }
          ];
        }
        {
          window-rule._children = [
            (match {app-id = "zen";})
            (match {app-id = "yazi";})
            (match {app-id = "mpv";})
            (match {app-id = "imv";})
            (match {app-id = "kitty";})
            (match {app-id = "neovim";})
            (match {app-id = "sioyek";})
            (match {app-id = "vesktop";})
            (match {app-id = "^libreoffice-.*$";})
            {open-maximized = true;}
          ];
        }
        {
          window-rule._children = [
            (match {app-id = "thunar";})
            (match {app-id = "pavucontrol";})
            (match {app-id = "blueman-manager";})
            (match {app-id = "nm-connection-editor";})
            (match {app-id = "chromium";})
            (match {app-id = "btop";})
            {open-floating = true;}
            {
              border = {
                on = {};
                width = 2;
              };
            }
            {shadow.on = {};}
          ];
        }
        {
          window-rule._children = [
            (match {app-id = "kitty";})
            (match {app-id = "sioyek";})
            (match {app-id = "neovim";})
            {default-column-display = "tabbed";}
          ];
        }
        {
          window-rule._children = [
            (match {app-id = "vesktop";})
            {scroll-factor = 0.4;}
          ];
        }
        {
          window-rule._children = [
            (match {app-id = "it.catboy.ripdrag";})
            {
              border = {
                active-color = "#a6e3a1";
                width = 2;
              };
            }
            {
              focus-ring = {
                active-color = "#a6e3a1";
                width = 5;
              };
            }
          ];
        }
        {
          window-rule._children = [
            (match {app-id = "sioyek";})
            (match {app-id = "neovim";})
            {open-on-workspace = "Work";}
            {open-focused = true;}
          ];
        }
        {
          window-rule._children = [
            (match {app-id = "zen";})
            (match {app-id = "yazi";})
            (match {app-id = "kitty";})
            {open-on-workspace = "Utilities";}
            {open-focused = true;}
          ];
        }
        {
          window-rule._children = [
            (match {app-id = "vesktop";})
            (match {app-id = "YouTube Music Desktop App";})
            {open-on-workspace = "Entertainment";}
            {open-focused = true;}
          ];
        }
        {
          window-rule._children = [
            (match {app-id = "Ds9.tcl";})
            (match {app-id = "Toplevel";})
            (match {app-id = "pyraf";})
            (match {title = "PyRAF";})
            {open-floating = true;}
            {
              border = {
                on = {};
                width = 2;
              };
            }
            {shadow.on = {};}
          ];
        }
        {
          window-rule._children = [
            (match {app-id = "yad";})
            {open-floating = true;}
            {open-focused = true;}
          ];
        }
        {
          window-rule._children = [
            (match {app-id = "dev.noctalia.Noctalia";})
            {open-floating = true;}
          ];
        }
        {
          layer-rule._children = [
            (match {namespace = "overview";})
            {place-within-backdrop = true;}
          ];
        }
        {
          layer-rule._children = [
            (match {namespace = "vicinae";})
            (match {namespace = "quickshell:notification";})
            {block-out-from = "screencast";}
          ];
        }
      ];
    };
  };

  # Keep the current Arch-managed Niri config available as a fallback during rollout.
  xdg.configFile."niri/config.kdl".target = "niri-nix/config.kdl";
  xdg.configFile."niri-nix/scripts/utils" = {
    source = ./scripts/utils;
    executable = true;
  };
  xdg.configFile."niri-nix/scripts/syncshot-runner" = {
    source = ./scripts/syncshot-runner;
    executable = true;
  };
  xdg.configFile."niri-nix/data/gitmojis.json".source = ./data/gitmojis.json;

  xdg.portal = {
    extraPortals = [pkgs.gnome-keyring];
    config.niri = {
      default = ["gnome" "gtk"];
      "org.freedesktop.impl.portal.Access" = ["gtk"];
      "org.freedesktop.impl.portal.FileChooser" = ["termfilechooser"];
      "org.freedesktop.impl.portal.ScreenCast" = ["gnome"];
      "org.freedesktop.impl.portal.Secret" = ["gnome-keyring"];
    };
  };

  services.polkit-gnome.enable = true;

  systemd.user.services.cliphist = {
    Unit = {
      Description = "Wayland clipboard history";
      After = ["niri.service"];
      PartOf = ["graphical-session.target"];
    };
    Service = {
      ExecStart = "${pkgs.wl-clipboard}/bin/wl-paste --watch ${pkgs.cliphist}/bin/cliphist store";
      Restart = "on-failure";
    };
    Install.WantedBy = ["niri.service"];
  };

  home.packages = with pkgs; [
    blueman
    cliphist
    grim
    hyprpicker
    imagemagick
    jq
    libnotify
    networkmanagerapplet
    pantheon.elementary-icon-theme
    slurp
    thunar
    wl-clipboard
    wofi
    yad
    zenity
  ];
}
