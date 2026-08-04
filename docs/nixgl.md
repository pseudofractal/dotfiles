# nixGL API in Graphical Modules

This repo exposes a single `maybeWrap` function via the Home Manager module system at `config.dotfiles.graphical.nixgl.maybeWrap`.

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

Use `config.dotfiles.graphical.nixgl.maybeWrap` directly — no imports needed:

```nix
{ pkgs, config, ... }: {
  programs.sioyek = {
    enable = true;
    package = config.dotfiles.graphical.nixgl.maybeWrap {
      package = pkgs.sioyek;
      bin = "sioyek";
    };
  };
}
```

`maybeWrap` accepts `{ package, bin ? null }` and returns the wrapped (or passthrough) package.

## Example 1: Simple `programs.*.package` app

```nix
{
  pkgs,
  config,
  ...
}: {
  programs.sioyek = {
    enable = true;
    package = config.dotfiles.graphical.nixgl.maybeWrap {
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
  config,
  ...
}: let
  wrappedVesktopPackage = let
    wrap = pkg: config.dotfiles.graphical.nixgl.maybeWrap {
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

## Example 3: `home.packages` app

```nix
{ pkgs, config, ... }: {
  home.packages = [
    pkgs.iproute2
    (config.dotfiles.graphical.nixgl.maybeWrap {
      package = pkgs.mesa-demos;
      bin = "glxinfo";
    })
  ];
}
```

## CARTA note

`modules/graphical/carta.nix` uses `config.dotfiles.graphical.nixgl.maybeWrap` to wrap the CARTA launcher on non-NixOS hosts.

- Launch command is `carta`.
- CARTA is started with a custom browser command so the frontend URL opens in Zen (`zen-twilight`) when available.

## Prism Launcher Exception

Prism Launcher is an intentional exception to the usual `maybeWrap` pattern.
The active module is `modules/graphical/new-prism.nix`; it builds a custom
launcher instead of passing `pkgs.prismlauncher` through `maybeWrap`. That
launcher preserves Prism's Qt plugin path and Java search path, and adds the
host `/usr/lib` and `/usr/lib64` directories needed by the current non-NixOS
GL setup before executing Prism's unwrapped binary.

`modules/graphical/prism-launcher.nix` is an older, inactive implementation
that uses the generic wrapper and should not replace the active module without
retesting Prism's GL behavior. Layering `maybeWrap` around the active package
would change the launch and library-resolution order, so it is not part of the
default configuration.

The normal desktop entry uses `prismlauncher %U`, which resolves the managed
profile command through `PATH`, just like a terminal launch. Prism-generated
instance shortcuts can record a separate executable path, so they should be
inspected independently if they stop using the active wrapper.
Noctalia is configured to launch applications as user systemd services, so its
environment should be checked separately if it cannot resolve the profile
command.
