# Repeated top-level nodes: startup entries, outputs, workspaces and
# window/layer rules. niri-nix renders a list under a real node name as
# repeated KDL nodes, so this evaluates to an attrset merged into
# `wayland.windowManager.niri.settings` (see default.nix).
{
  lib,
  pkgs,
}: let
  match = props: {match._props = props;};
  ids = map (app-id: match {inherit app-id;});
  rule = matches: extra: {_children = matches ++ extra;};
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
in {
  spawn-at-startup = [
    [(lib.getExe' pkgs.blueman "blueman-applet")]
    [(lib.getExe' pkgs.networkmanagerapplet "nm-applet") "--indicator"]
  ];

  output = [
    {
      _args = ["eDP-1"];
      scale = 1;
      transform = "normal";
      mode = "1920x1200@60.003";
    }
  ];

  workspace = [
    {_args = ["Work"];}
    {_args = ["Utilities"];}
    {_args = ["Entertainment"];}
  ];

  window-rule = [
    {
      geometry-corner-radius = [12.0 12.0 12.0 12.0];
      clip-to-geometry = true;
    }
    {
      _children =
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
      "nchat"
      "nvim"
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
      ])
      floatingBorder)
    (rule (ids [
      "kitty"
      "sioyek"
      "nvim"
    ]) [{default-column-display = "tabbed";}])
    (rule (ids ["vesktop"]) [{scroll-factor = 0.4;}])
    {
      _children =
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
    (onWorkspace ["sioyek" "nvim"] "Work")
    (onWorkspace ["zen" "yazi" "kitty"] "Utilities")
    (onWorkspace ["nchat" "vesktop" "YouTube Music Desktop App"] "Entertainment")
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
  ];

  layer-rule = [
    {
      _children =
        [(match {namespace = "^noctalia-overview";})]
        ++ [{place-within-backdrop = true;}];
    }
    {
      _children =
        [
          (match {namespace = "vicinae";})
          (match {namespace = "noctalia-notification";})
        ]
        ++ [{block-out-from = "screencast";}];
    }
  ];
}
