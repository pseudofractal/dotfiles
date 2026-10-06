# Rebuild notes

Run these commands from the repository root. Both commands include uncommitted
changes, so the worktree does not need to be clean.

## Home Manager

This is the normal rebuild command:

```bash
home-manager switch --flake .#pseudofractal
```

The Fish shortcut is `rebuild`. Use `rebuild --system` for System Manager,
and `rebuild --backup` when Home Manager needs to move an existing file.

Use it after changing anything under `modules/` or
`hosts/arch/default.nix`. This includes packages, dotfiles, user services,
niri settings, Noctalia, and Vicinae.

A logout is usually unnecessary. Log out and back in when changing how the
niri session starts, or when the running compositor does not pick up a config
change.

If Home Manager refuses to replace an existing file, keep a backup during the
switch:

```bash
home-manager switch --flake .#pseudofractal -b backup
```

`systemd.user.startServices` is `false`, so a switch never starts services
itself — long oneshot jobs such as Lieer full syncs would otherwise block the
activation. The `rebuild` shortcut compensates: after a successful Home
Manager switch it restarts all user timers, so new or changed schedules take
effect. Restarting a timer only re-arms its schedule; it never runs the job,
and running syncs are left undisturbed. The shortcut also reprints Home
Manager's suggested service restarts in yellow at the end of a successful
switch, so they are not buried in the activation log.

If you switch without `rebuild`, re-arm them manually, e.g.:

```bash
systemctl --user restart lieer-iiser.timer lieer-personal.timer email-classify-backfill.timer
```

## System Manager

System Manager owns the SDDM session entry, `/run/system-manager/sw`,
`/run/opengl-driver`, and the files declared in `hosts/arch/system.nix`.

Run it after changing `hosts/arch/system.nix` or the `systemConfigs.arch`
definition in `flake.nix`:

```bash
nix run 'github:numtide/system-manager' -- switch --sudo --flake "$PWD#arch"
```

Log out and select **Niri (Nix)** again if the session wrapper or niri package
changed. A Home Manager switch does not deploy System Manager changes.

Useful checks:

```bash
readlink -f /run/system-manager/sw/bin/niri
readlink -f ~/.nix-profile/bin/niri
niri msg outputs
systemctl --user status noctalia.service
```

Both `readlink` commands should resolve to the same niri store package.

## Binary caches

The project caches live in `~/.config/nix/nix.conf` because
`accept-flake-config` is disabled:

```text
extra-substituters = https://niri-nix.cachix.org https://noctalia.cachix.org https://vicinae.cachix.org
extra-trusted-public-keys = niri-nix.cachix.org-1:SvFtqpDcf7Sm1SMJdby1/+Y+6f3Yt3/3PMcSTKPJNJ0= noctalia.cachix.org-1:pCOR47nnMEo5thcxNDtzWpOxNFQsBRglJzxWPp3dkU4= vicinae.cachix.org-1:1kDrfienkGHPYbkpNj1mWTr7Fm1+zcenzgTizIcI3oc=
```

Without these entries, Nix may build large packages locally.

## Updating inputs

Update one input at a time:

```bash
nix flake lock --update-input <name>
git diff flake.lock
```

Do not run a plain `nix flake update`; moving every input at once makes
breakage difficult to isolate.

Some inputs are pinned deliberately:

- `vicinae` and its nixpkgs revision match the available binary cache.
  Following the root nixpkgs would rebuild everything from source, and
  vicinae's source build is broken against it (gcc15Stdenv vs system numen
  GLIBCXX skew). Rev-pinned so plain `nix flake lock` can never drift it off
  the cached build. Refresh the rev and its paired nixpkgs together from
  upstream's lock (currently v0.29.1 on nixpkgs `7a0f122f`); the flake's
  `lib` is also needed for `mkVicinaeExtension`, so nixpkgs' `vicinae`
  package is not a substitute.
- `niri-nix` provides the overlay used by both Home Manager and System
  Manager. Building niri against the root nixpkgs keeps it compatible with
  `/run/opengl-driver`. Its own nixpkgs input is pinned to the revision its
  CI pushed to the cache, with no follows, so the store paths match the
  cached builds exactly.
- `nixpkgs-zotero` keeps Zotero 10.0.2 on a compatible Firefox ESR release
  (the last nixpkgs with firefox-esr-140; Zotero's build scripts abort
  against ESR 153's ActorManagerParent). Temporary until upstream adapts
  Zotero.
- `nixpkgs-llama` freezes both llama.cpp servers, so routine nixpkgs updates
  never trigger a from-source CUDA rebuild.
