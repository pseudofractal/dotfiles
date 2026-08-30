# nixGL In Graphical Modules

The graphical module exposes `config.dotfiles.graphical.nixgl.maybeWrap` for
applications that need host OpenGL libraries on non-NixOS systems.

## Host Configuration

Configure nixGL once per host, usually in `hosts/<host>/default.nix`:

```nix
dotfiles.graphical.nixgl = {
  enable = true;
  package = "nixGLIntel";
};
```

`nixGLIntel` is nixGL's Mesa wrapper and supports the AMD iGPU despite its
name. It is the stable default for the hybrid ASUS host in this repository.
Set `package` to another package exposed by the nixGL input when required.

When enabled, graphical packages are wrapped only on non-NixOS hosts. On
NixOS, they are returned unchanged.

The generic wrapper preserves NVIDIA offload variables from the host. Normal
launches use Mesa/AMD; `switcherooctl launch -g 1 ...` selects the host NVIDIA
libraries for an explicit offload launch. This keeps GPU selection under
`supergfxctl` and `switcherooctl` rather than in a Home Manager generation.

## Module API

Call the helper directly from a graphical module:

```nix
{ pkgs, config, ... }: {
  home.packages = [
    (config.dotfiles.graphical.nixgl.maybeWrap {
      package = pkgs.mesa-demos;
      bin = "glxinfo";
    })
  ];
}
```

The helper accepts `{ package, bin ? null }`:

- `package` is the package to install.
- `bin` selects the executable when the package contains multiple programs.
- Omitting `bin` uses `meta.mainProgram`, falling back to the package name.

The helper wraps the package's exported executable with nixGL and retains the
package's own wrapper, resources, and `.override` interface. Do not replace a
package with its unwrapped variant unless its complete runtime environment is
being recreated deliberately.

For the discrete GPU in Hybrid mode:

```bash
switcherooctl list
switcherooctl launch -g 1 glxinfo -B
```

The second command should report the NVIDIA renderer. Without `-g 1`, the
same command should report the AMD renderer.

## Package Overrides

Packages that are overridden by a consuming Home Manager module can use the
helper directly. The helper reapplies itself after an override:

```nix
{ pkgs, config, ... }: {
  programs.vesktop = {
    enable = true;
    package = config.dotfiles.graphical.nixgl.maybeWrap {
      package = pkgs.vesktop;
      bin = "vesktop";
    };
    vencord.useSystem = true;
  };
}
```

## Prism Launcher

Prism Launcher is intentionally not passed through `maybeWrap`. Its active
implementation is `modules/graphical/prism-launcher.nix`.

The module retains Prism's package data but launches the unwrapped executable
with the environment normally supplied by the nixpkgs wrapper. It includes
the Qt plugin and QML paths, SVG and image-format plugins, runtime utilities,
Java search paths, package data paths, and host `/usr/lib` and `/usr/lib64`
paths required by the non-NixOS graphics setup.

It also sets `NIX_LAUNCHER_WRAPPER`, allowing Prism-generated instance
launchers to use the managed executable rather than a stale direct path.

Prism's `InstanceDir` must be an absolute path because Prism does not expand
`~` in its configuration. The current configuration uses
`/home/pseudofractal/Games/prismlauncher` through
`config.home.homeDirectory`.

Prism themes use Home Manager's native
`programs.prismlauncher.themes` option. Do not route this package through
`maybeWrap`, since doing so changes the library-resolution order needed by
the custom non-NixOS launcher.

## Verification

```bash
nix fmt -- --ci
nix flake check --no-build
nix eval .#homeConfigurations.pseudofractal.config.home.packages --apply builtins.length
nix build --no-link .#homeConfigurations.pseudofractal.activationPackage
home-manager switch --flake .
```

## Troubleshooting

If Prism icons are missing, verify that the active launcher exposes the
`qtsvg` and `qtimageformats` plugin directories. Prism logs should show
`Icon themes initialized` and `Instance icons initialized` during startup.

If Prism loads no instances, inspect `InstanceDir` in
`~/.local/share/PrismLauncher/prismlauncher.cfg`. A literal `~/...` path is
resolved below Prism's data directory rather than the user's home directory.

If a generic wrapped application fails to start, check that the requested
`bin` exists and that the original package executable is being called after
the nixGL wrapper. For NVIDIA offload failures, verify that the launch was
started with `switcherooctl launch -g 1` and that the dGPU is available in the
current `supergfxctl` mode.
