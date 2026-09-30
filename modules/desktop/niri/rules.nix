# Repeated `window-rule` / `layer-rule` blocks, startup entries and outputs.
# Evaluates to the list assigned to `wayland.windowManager.niri.settings._children`.
{
  lib,
  pkgs,
  noctalia,
}: let
  match = props: {match._props = props;};
  ids = map (app-id: match {inherit app-id;});
  rule = matches: extra: {window-rule._children = matches ++ extra;};
  onWorkspace = appIds: workspace:
    rule (ids appIds) [
      {open-on-workspace = workspace;}
      {open-focused = true;}
    ];
  floatingBorder = [
    {open-floating = true;}
    {
      border = {
        on = {};
        width = 2;
      };
    }
    {shadow.on = {};}
  ];
in [
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
    window-rule._children =
      [(match {is-window-cast-target = true;})]
      ++ [
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
  (rule (ids [
      "zen"
      "yazi"
      "mpv"
      "imv"
      "kitty"
      "neovim"
      "sioyek"
      "vesktop"
      "^libreoffice-.*$"
    ]) [{open-maximized = true;}])
  (rule (ids [
      "thunar"
      "pavucontrol"
      "blueman-manager"
      "nm-connection-editor"
      "chromium"
      "btop"
    ]) floatingBorder)
  (rule (ids [
      "kitty"
      "sioyek"
      "neovim"
    ]) [{default-column-display = "tabbed";}])
  (rule (ids ["vesktop"]) [{scroll-factor = 0.4;}])
  {
    window-rule._children =
      [(match {app-id = "it.catboy.ripdrag";})]
      ++ [
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
  (onWorkspace ["sioyek" "neovim"] "Work")
  (onWorkspace ["zen" "yazi" "kitty"] "Utilities")
  (onWorkspace ["vesktop" "YouTube Music Desktop App"] "Entertainment")
  (rule
    [
      (match {app-id = "Ds9.tcl";})
      (match {app-id = "Toplevel";})
      (match {app-id = "pyraf";})
      (match {title = "PyRAF";})
    ]
    floatingBorder)
  (rule (ids ["yad"]) [
    {open-floating = true;}
    {open-focused = true;}
  ])
  (rule (ids ["dev.noctalia.Noctalia"]) [{open-floating = true;}])
  {
    layer-rule._children =
      [(match {namespace = "overview";})]
      ++ [{place-within-backdrop = true;}];
  }
  {
    layer-rule._children =
      [
        (match {namespace = "vicinae";})
        (match {namespace = "quickshell:notification";})
      ]
      ++ [{block-out-from = "screencast";}];
  }
]
