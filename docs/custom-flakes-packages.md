# Custom Flakes and Package Placement Guide

This guide explains how to add new packages and custom flake inputs in this repo, where to put them, and how to verify the result.

It covers both:

- Desktop Home Manager flow (`homeConfigurations.pseudofractal`)
- Android/Nix-on-Droid flow (`nixOnDroidConfigurations.koch`)

## Quick Start Cheat Sheet

### Most common: add a normal package (desktop)

1. Add it to the right category module (`modules/core|cli|tui|programming|graphical`).
1. Put it in `home.packages` (or `programs.<name>.enable` if HM module exists).
1. Run:

```bash
home-manager switch --flake . --impure
```

### Add a package from a custom flake input

1. Add input in `flake.nix`.
1. Lock it:

```bash
nix flake lock --update-input myflake
```

3. Use it in a module:

```nix
{ pkgs, inputs, ... }: let
  system = pkgs.stdenv.hostPlatform.system;
in {
  home.packages = [ inputs.myflake.packages.${system}.mytool ];
}
```

4. Apply:

```bash
home-manager switch --flake . --impure
```

### Android-only package

- System package: `hosts/android/system.nix` -> `environment.packages`
- User-space HM package: `hosts/android/home.nix` -> `home.packages`

### Do / Don't

- **Do** add shared packages in `modules/*` category modules.
- **Do** prefer `programs.<name>.enable` when a Home Manager module exists.
- **Do** keep host files for host-specific or platform-specific differences.
- **Don't** put shared/common packages directly in `hosts/arch/default.nix` or `hosts/android/home.nix` unless truly host-only.
- **Don't** skip lock updates after adding a new input.

## Architecture Overview

### 1) Inputs are declared in one place

- File: `flake.nix`
- External sources go under `inputs = { ... };`
- Repo currently pins key toolchains with `follows` for compatibility.

Example pattern:

```nix
myflake = {
  url = "github:owner/repo";
  inputs.nixpkgs.follows = "nixpkgs";
};
```

### 2) Inputs are threaded into modules

- File: `flake.nix`
- `outputs = { ... } @ inputs:` captures all inputs.
- `extraSpecialArgs` passes `inputs` to modules.

So in modules, you can use `inputs.<name>...` directly.

### 3) Module composition

- Main shared module tree: `modules/default.nix`
- External Home Manager modules are imported there (for example `inputs.sops-nix.homeManagerModules.sops`).
- Graphical modules are loaded only on non-Android hosts.

## Where to Add Packages

Use this decision order:

1. **Shared category module first** (preferred)

   - `modules/core/*` for shell/systemwide tools
   - `modules/cli/*` for CLI app groups
   - `modules/tui/*` for terminal UI apps
   - `modules/programming/*` for dev toolchains/editors
   - `modules/graphical/*` for desktop GUI apps

1. **Use Home Manager program modules when available**

   - Prefer `programs.<name>.enable = true;` when the module exists.
   - Use `programs.<name>.package = ...;` only when you need a custom package source/override.

1. **Use `home.packages` for plain binaries**

   - If no dedicated HM module/config is needed, add package to the right category module’s `home.packages`.

1. **Use host files only for host-specific needs**

   - Desktop host: `hosts/arch/default.nix`
   - Android HM user config: `hosts/android/home.nix`
   - Android system-level packages: `hosts/android/system.nix` (`environment.packages`)

## Add a Custom Flake Input

### Step 1: Declare input in `flake.nix`

```nix
inputs = {
  nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";

  myflake = {
    url = "github:owner/repo";
    inputs.nixpkgs.follows = "nixpkgs";
  };
};
```

Notes:

- Use `follows` for `nixpkgs` (and sometimes `home-manager`) when you want to reduce version skew.
- Not every flake exposes the same outputs; inspect docs/README for supported attrs.

### Step 2: Update lock file

```bash
nix flake lock --update-input myflake
```

### Step 3: Consume the input

Pick one of these patterns.

#### A) Import a Home Manager module from the input

In `modules/default.nix`:

```nix
imports = [
  # ...existing imports
  inputs.myflake.homeManagerModules.default
];
```

#### B) Install a package from the input

In a module (for example `modules/tui/mytool.nix`):

```nix
{ pkgs, inputs, ... }: let
  system = pkgs.stdenv.hostPlatform.system;
in {
  home.packages = [
    inputs.myflake.packages.${system}.mytool
  ];
}
```

#### C) Use overlay exported by the input (if provided)

If an input documents overlays, add that overlay in the right place and then use packages from `pkgs` normally.

## End-to-End Examples

### Example 0: Add CARTA from upstream AppImage (when nixpkgs package is unavailable)

If a tool is not in nixpkgs (or missing for your pinned revision), package a pinned upstream asset in a module.

- Keep `version` and `hash` in one place in the module.
- Prefer stable release URLs (for reproducibility), not `releases/latest`.
- For CARTA, use release assets like:
  - `carta.AppImage.x86_64.tgz`
  - `carta.AppImage.aarch64.tgz`
- Add the package through the normal module tree (for CARTA: `modules/graphical/carta.nix`).

### Example 1: Add a nixpkgs package to desktop GUI stack

1. Create/update a module under `modules/graphical/`.
1. Add package in `home.packages`.
1. Ensure module is imported in `modules/graphical/default.nix`.

```nix
{ pkgs, ... }: {
  home.packages = with pkgs; [
    zotero
  ];
}
```

### Example 2: Add a package from a custom input

```nix
{ pkgs, inputs, ... }: let
  system = pkgs.stdenv.hostPlatform.system;
in {
  home.packages = [
    inputs.myflake.packages.${system}.mytool
  ];
}
```

### Example 3: Add Android-only package

For system packages on Nix-on-Droid, use `hosts/android/system.nix`:

```nix
{ pkgs, ... }: {
  environment.packages = with pkgs; [
    git
    openssh
    my-android-tool
  ];
}
```

For Android Home Manager user-space packages, use `hosts/android/home.nix` `home.packages`.

## Graphical + nixGL Notes

For desktop graphical apps that need GL wrapping:

- see `docs/nixgl.md`
- current generic hook is `dotfiles.graphical.nixgl.requests.home`
- some `programs.*.package` apps still use manual local wrapped-package pattern

## Verification Commands

### Desktop (Arch HM)

```bash
nix eval .#homeConfigurations.pseudofractal.config.home.packages --apply builtins.length
nix build .#homeConfigurations.pseudofractal.activationPackage --impure
home-manager switch --flake . --impure
```

### Android (Nix-on-Droid)

```bash
nix build .#nixOnDroidConfigurations.koch.activationPackage
```

## Troubleshooting

- **Untracked new file not picked up by flake eval**

  - If a new file is not included in source filtering yet, stage it once before build/switch.

- **Wrong package attr for current system**

  - Verify package path includes `${system}` where needed.

- **Version skew between flakes**

  - Add or correct `inputs.<name>.inputs.nixpkgs.follows = "nixpkgs"`.

- **Pure eval failures from impure dependencies**

  - Use the repo’s current desktop flow: `home-manager switch --flake . --impure`.

## Maintenance Checklist

- Add input in `flake.nix` with sensible `follows`.
- Add usage in the correct module category.
- Avoid putting shared packages directly in host files.
- Keep docs updated when introducing special package handling patterns.
