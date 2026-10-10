# nixGL in graphical modules

Graphical modules get `config.dotfiles.graphical.nixgl.maybeWrap` for apps that need host OpenGL libraries off NixOS.

## Host configuration

Set nixGL once per host, usually in `hosts/<host>/default.nix`:

```nix
dotfiles.graphical.nixgl = {
  enable = true;
  package = "nixGLIntel";
};
```

`nixGLIntel` is nixGL's Mesa wrapper. The name lies a little; it drives the AMD iGPU fine, and it's the default for the hybrid ASUS host here. Point `package` at another package from the nixGL input when you need to.

With it enabled, wrapping happens only off NixOS. On NixOS packages pass through untouched. Wrapped desktop apps stay on the AMD iGPU in Integrated and Hybrid alike; games and compute can still opt into NVIDIA without host libraries leaking into Nix processes.

## Module API

Call the helper straight from a graphical module:

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

The helper takes `{ package, bin ? null, launcherWrapper ? false }`:

- `package` is what gets installed.
- `bin` picks the executable when the package ships several programs.
- Without `bin` it tries `meta.mainProgram`, then the package name.
- `launcherWrapper = true` points `NIX_LAUNCHER_WRAPPER` at the outer wrapped executable so generated child launchers re-enter nixGL.

Wrapping keeps the package's own wrapper, resources and `.override` interface. Don't swap in the unwrapped variant unless you're rebuilding its whole runtime env on purpose.

To check which GPU got picked:

```bash
supergfxctl --get
glxinfo -B
```

Wrapped apps should report the AMD renderer in Integrated and Hybrid both. `AsusEgpu` belongs to an attached XG Mobile and isn't used as an internal-GPU mode here.

## Package overrides

A Home Manager module that overrides its package can still use the helper; the helper reapplies itself after the override:

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

Prism wraps with `maybeWrap` around `pkgs.prismlauncher`, keeping its Qt wrapper, Java discovery, desktop entry and game runtime libraries. The outer wrapper clears inherited graphics variables and sets up nixGL's Mesa stack. Prism's own wrapper then appends its runtime libraries instead of swapping that stack for `/run/opengl-driver`.

With wrapping active, `launcherWrapper = true` makes generated instance launchers re-enter the outer wrapper instead of slipping past nixGL.

Prism's `InstanceDir` must be absolute because Prism doesn't expand `~` in its config. Ours is `/home/pseudofractal/Games/prismlauncher`, via `config.home.homeDirectory`.

Prism themes go through Home Manager's native `programs.prismlauncher.themes` option.

## Verification

```bash
nix fmt -- --ci
nix flake check --no-build
nix eval .#homeConfigurations.pseudofractal.config.home.packages --apply builtins.length
nix build --no-link .#homeConfigurations.pseudofractal.activationPackage
home-manager switch --flake .
```

## Troubleshooting

Missing Prism icons: check the active launcher exposes the `qtsvg` and `qtimageformats` plugin dirs. The logs should show `Icon themes initialized` and `Instance icons initialized` during startup.

No instances listed: look at `InstanceDir` in `~/.local/share/PrismLauncher/prismlauncher.cfg`. A literal `~/...` path resolves under Prism's data dir, not your home.

Legacy LWJGL 2 instances failing with `Could not locate OpenAL library`: usually a stale hand-pinned Java runtime. Drop the instance's Java-location override or pick the current Java 8 from `PRISMLAUNCHER_JAVA_PATHS`.

A wrapped app that won't start at all: check the requested `bin` exists and the original package executable actually runs after the nixGL wrapper. For NVIDIA work, check `supergfxctl` says `Hybrid`, then use a dedicated NVIDIA wrapper or set offload inside the child workload. `maybeWrap` clears inherited offload variables.
