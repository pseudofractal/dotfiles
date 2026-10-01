{
  config,
  inputs,
  lib,
  pkgs,
  ...
}: let
  noctalia = lib.getExe config.programs.noctalia.package;
  tools = pkgs.callPackage ./tools.nix {};
  inherit (tools) niriUtils syncshotRunner;
in {
  imports = [inputs.niri-nix.homeModules.default];

  wayland.windowManager.niri = {
    enable = true;
    # Overlay build, not inputs.niri-nix.packages: the compositor shares
    # /run/opengl-driver with the rest of the system, so its Mesa/glibc
    # must match. (Upstream binaries silently get zero outputs.)
    package = pkgs.niri-unstable;
    validation.enable = true;

    settings =
      {
        input = {
          keyboard = {
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
        debug.honor-xdg-activation-with-invalid-serial = {};

        layout = {
          gaps = 2;
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

        binds = import ./binds.nix {
          inherit lib pkgs noctalia niriUtils syncshotRunner;
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
        # Repeated top-level nodes (startup, outputs, workspaces, rules).
      }
      // (import ./rules.nix {
        inherit lib pkgs;
      });
  };

  xdg.portal = {
    extraPortals = with pkgs; [
      gnome-keyring
      xdg-desktop-portal-gnome
      xdg-desktop-portal-gtk
    ];
    config.niri = {
      default = ["gnome" "gtk"];
      "org.freedesktop.impl.portal.Access" = ["gtk"];
      "org.freedesktop.impl.portal.FileChooser" = ["termfilechooser"];
      "org.freedesktop.impl.portal.ScreenCast" = ["gnome"];
      "org.freedesktop.impl.portal.Secret" = ["gnome-keyring"];
    };
  };

  services.polkit-gnome.enable = true;

  # niri-nix home module (unlike home-manager upstream) ships no systemd
  # units – link them from the package so niri-session / niri.service still work.
  systemd.user.packages = [pkgs.niri-unstable];

  home.packages = with pkgs; [
    blueman
    grim
    imagemagick
    jq
    libnotify
    networkmanagerapplet
    niriUtils
    pantheon.elementary-icon-theme
    slurp
    syncshotRunner
    thunar
    wev
    wl-clipboard
    xwayland-satellite-unstable
    yad
  ];
}
