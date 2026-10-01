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
NixOS, they are returned unchanged. Wrapped desktop applications stay on the
AMD iGPU in both Integrated and Hybrid modes; games and compute workloads can
opt into the NVIDIA GPU without injecting host libraries into Nix processes.

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

The helper accepts `{ package, bin ? null, launcherWrapper ? false }`:

- `package` is the package to install.
- `bin` selects the executable when the package contains multiple programs.
- Omitting `bin` uses `meta.mainProgram`, falling back to the package name.
- `launcherWrapper = true` sets `NIX_LAUNCHER_WRAPPER` to the outer wrapped
  executable so generated child launchers re-enter nixGL.

The helper wraps the package's exported executable with nixGL and retains the
package's own wrapper, resources, and `.override` interface. Do not replace a
package with its unwrapped variant unless its complete runtime environment is
being recreated deliberately.

To verify the selected GPU:

```bash
supergfxctl --get
glxinfo -B
```

Wrapped applications should report the AMD renderer in both Integrated and
Hybrid modes. `AsusEgpu` is reserved for an attached XG Mobile and is not used
as an internal-GPU mode here.

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

Prism Launcher uses `maybeWrap` around `pkgs.prismlauncher`, preserving its Qt
wrapper, Java discovery, desktop entry, and game runtime libraries. The outer
wrapper clears inherited graphics variables and establishes nixGL's Mesa
stack. Prism's package wrapper then appends its runtime libraries instead of
replacing that stack with `/run/opengl-driver`.

When nixGL wrapping is active, `launcherWrapper = true` makes generated
instance launchers re-enter the outer wrapper instead of bypassing nixGL.

Prism's `InstanceDir` must be an absolute path because Prism does not expand
`~` in its configuration. The current configuration uses
`/home/pseudofractal/Games/prismlauncher` through
`config.home.homeDirectory`.

Prism themes use Home Manager's native
`programs.prismlauncher.themes` option.

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

For legacy LWJGL 2 instances, `Could not locate OpenAL library` can indicate a
stale manually pinned Java runtime. Disable the instance's Java-location
override or select the current Java 8 exposed by `PRISMLAUNCHER_JAVA_PATHS`.

If a generic wrapped application fails to start, check that the requested
`bin` exists and that the original package executable is being called after
the nixGL wrapper. For NVIDIA workloads, verify that `supergfxctl` reports
`Hybrid` and use a dedicated NVIDIA wrapper or apply offload configuration
inside the child workload; `maybeWrap` clears inherited offload variables.
