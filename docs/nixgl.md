# nixGL API in Graphical Modules

This repo uses one shared nixGL helper at `modules/graphical/nixgl-helper.nix`.

## Host-level options (user-facing)

Set these once per host, usually in `hosts/<host>/default.nix`:

```nix
dotfiles.graphical.nixgl = {
  enable = true;
  package = "nixGLDefault"; # e.g. nixGLIntel, nixGLNvidia
};
```

Behavior:
- wrapping applies only when `enable = true` and host is non-NixOS
- on NixOS, packages are returned unwrapped automatically

## Module-level API (for app modules)

Import helper in graphical modules:

```nix
nixgl = import ./nixgl-helper.nix {
  inherit config lib pkgs inputs isNixOS;
};
```

Available helpers:
- `nixgl.maybeWrap { package; bin ? null; }`
- `nixgl.enabled`
- `nixgl.getProgramName`
- `nixgl.resolveNixGLPkg`

`maybeWrap` is the one you should use in almost all app modules.

## Example 1: Simple `programs.*.package` app

```nix
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
in {
  programs.sioyek = {
    enable = true;
    package = nixgl.maybeWrap {
      package = pkgs.sioyek;
      bin = "sioyek";
    };
  };
}
```

## Example 2: More involved app (`vesktop`)

`programs.vesktop` internally calls `.override` on `package`, so keep override capability when wrapping.

```nix
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
    wrap = pkg: nixgl.maybeWrap {
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
  };
}
```

## Example 3: Declarative wrapping for `home.packages`

Use request list when app is installed via `home.packages` instead of `programs.<app>.package`:

```nix
{ pkgs, ... }: {
  home.packages = [ pkgs.iproute2 ];

  dotfiles.graphical.nixgl.requests.home = [
    {
      package = pkgs.mesa-demos;
      bin = "glxinfo";
    }
  ];
}
```

## CARTA note

`modules/graphical/carta.nix` registers CARTA through `dotfiles.graphical.nixgl.requests.home` so it is wrapped automatically on non-NixOS hosts.

- Launch command is `carta`.
- CARTA is started with a custom browser command so the frontend URL opens in Zen (`zen-twilight`) when available.
