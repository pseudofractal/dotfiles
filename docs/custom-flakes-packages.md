# Adding packages and flake inputs

Where new packages and custom flake inputs go, and how to check the result.

Two flows: desktop Home Manager (`homeConfigurations.pseudofractal`) and Android/Nix-on-Droid (`nixOnDroidConfigurations.koch`).

## Quick start

### Most common: a normal desktop package

1. Add it to the right category module (`modules/core|cli|tui|programming|graphical`).
1. Put it in `home.packages` (or `programs.<name>.enable` if a Home Manager module exists).
1. Run:

```bash
home-manager switch --flake . --impure
```

### A package from a custom flake input

1. Add the input in `flake.nix`.
1. Lock it:

```bash
nix flake lock --update-input myflake
```

1. Use it in a module:

```nix
{ pkgs, inputs, ... }: let
  system = pkgs.stdenv.hostPlatform.system;
in {
  home.packages = [ inputs.myflake.packages.${system}.mytool ];
}
```

1. Apply:

```bash
home-manager switch --flake . --impure
```

### Android-only packages

- System package: `hosts/android/system.nix` → `environment.packages`
- User-space HM package: `hosts/android/home.nix` → `home.packages`

### Rules of thumb

- Shared packages go in `modules/*` category modules.
- Prefer `programs.<name>.enable` when a Home Manager module exists.
- Host files are for host-specific or platform differences.
- Don't put shared packages in `hosts/arch/default.nix` or `hosts/android/home.nix` unless they're truly host-only.
- Don't skip the lock update after adding an input.

## How it fits together

### Inputs live in one place

- File: `flake.nix`
- External sources go under `inputs = { ... };`
- Key toolchains here pin `follows` for compatibility.

```nix
myflake = {
  url = "github:owner/repo";
  inputs.nixpkgs.follows = "nixpkgs";
};
```

### Inputs reach modules through the flake

- File: `flake.nix`
- `outputs = { ... } @ inputs:` grabs every input.
- `extraSpecialArgs` hands `inputs` to modules.

So modules use `inputs.<name>...` directly.

### Module layout

- Shared tree root: `modules/default.nix`
- External Home Manager modules get imported there (e.g. `inputs.sops-nix.homeManagerModules.sops`).
- Graphical modules load only on non-Android hosts.

## Where to add packages

In this order:

1. Shared category module first (preferred):

   - `modules/core/*` for shell/systemwide tools
   - `modules/cli/*` for CLI app groups
   - `modules/tui/*` for terminal UI apps
   - `modules/programming/*` for dev toolchains/editors
   - `modules/graphical/*` for desktop GUI apps

1. Home Manager program modules when one exists:

   - Prefer `programs.<name>.enable = true;`.
   - `programs.<name>.package = ...;` only for a custom package source/override.

1. `home.packages` for plain binaries:

   - No dedicated HM module or config needed: drop the package in the right category module's `home.packages`.

1. Host files only for host-specific needs:

   - Desktop host: `hosts/arch/default.nix`
   - Android HM user config: `hosts/android/home.nix`
   - Android system-level packages: `hosts/android/system.nix` (`environment.packages`)

## Adding a custom flake input

### Declare it in `flake.nix`

```nix
inputs = {
  nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";

  myflake = {
    url = "github:owner/repo";
    inputs.nixpkgs.follows = "nixpkgs";
  };
};
```

- `follows` on `nixpkgs` (sometimes `home-manager` too) cuts version skew.
- Not every flake exposes the same outputs; check its docs/README for supported attrs.

### Lock it

```bash
nix flake lock --update-input myflake
```

### Consume it

One of these patterns.

#### A) Import a Home Manager module from the input

In `modules/default.nix`:

```nix
imports = [
  # ...existing imports
  inputs.myflake.homeManagerModules.default
];
```

#### B) Install a package from the input

In a module (e.g. `modules/tui/mytool.nix`):

```nix
{ pkgs, inputs, ... }: let
  system = pkgs.stdenv.hostPlatform.system;
in {
  home.packages = [
    inputs.myflake.packages.${system}.mytool
  ];
}
```

#### C) Use an overlay from the input (if it ships one)

If the input documents overlays, add the overlay in the right place, then use packages from `pkgs` normally.

## Examples

### CARTA from an upstream AppImage (nixpkgs has no package)

If a tool is missing from nixpkgs (or from the pinned revision), package a pinned upstream asset in a module.

- Keep `version` and `hash` together in the module.
- Prefer stable release URLs for reproducibility, not `releases/latest`.
- For CARTA, release assets like:
  - `carta.AppImage.x86_64.tgz`
  - `carta.AppImage.aarch64.tgz`
- Add it through the normal module tree (CARTA: `modules/graphical/carta.nix`).

### A nixpkgs package in the desktop GUI stack

1. Create/update a module under `modules/graphical/`.
1. Add the package in `home.packages`.
1. Make sure `modules/graphical/default.nix` imports the module.

```nix
{ pkgs, ... }: {
  home.packages = with pkgs; [
    zotero
  ];
}
```

### A package from a custom input

```nix
{ pkgs, inputs, ... }: let
  system = pkgs.stdenv.hostPlatform.system;
in {
  home.packages = [
    inputs.myflake.packages.${system}.mytool
  ];
}
```

### An Android-only package

System packages on Nix-on-Droid go in `hosts/android/system.nix`:

```nix
{ pkgs, ... }: {
  environment.packages = with pkgs; [
    git
    openssh
    my-android-tool
  ];
}
```

Android Home Manager user-space packages go in `hosts/android/home.nix` `home.packages`.

## GL wrapping

Desktop graphical apps that need GL wrapping:

- see `docs/nixgl.md`
- generally `config.dotfiles.graphical.nixgl.maybeWrap { package = ...; bin = ...; }` in graphical modules
- `maybeWrap` keeps package-native wrappers and `.override` behavior; don't substitute an unwrapped package
- `launcherWrapper = true` only when generated child launchers must re-enter the outer nixGL wrapper
- wrapped desktop apps use the AMD iGPU in Integrated and Hybrid both; opt games and compute workloads into NVIDIA explicitly

## Verification

### Desktop (Arch HM)

```bash
nix eval .#homeConfigurations.pseudofractal.config.home.packages --apply builtins.length
nix build .#homeConfigurations.pseudofractal.activationPackage
home-manager switch --flake .
```

### Android (Nix-on-Droid)

```bash
nix build .#nixOnDroidConfigurations.koch.activationPackage
```

## Troubleshooting

- New file invisible to flake eval: untracked files fall outside source filtering, so stage it once before build/switch.
- Wrong package attr for this system: check the path carries `${system}` where needed.
- Version skew between flakes: add or fix `inputs.<name>.inputs.nixpkgs.follows = "nixpkgs"`.
- Pure eval choking on impure deps: this repo's desktop flow is `home-manager switch --flake . --impure`.

## Checklist

- Input in `flake.nix` with sensible `follows`.
- Usage in the right module category.
- No shared packages sitting in host files.
- Docs updated when a new special-handling pattern appears.
