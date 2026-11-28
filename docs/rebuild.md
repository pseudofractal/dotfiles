# Rebuild notes

Run from the repo root. Both commands pick up uncommitted changes, so a clean tree isn't needed.

## Home Manager

The normal rebuild:

```bash
nh home switch -c pseudofractal ~/dotfiles
# or directly:
home-manager switch --flake .#pseudofractal
```

The fish shortcut is `rebuild`. On Arch it wraps `nh home switch` (falling back to `home-manager switch` before `nh` is installed) so builds show live `rom` progress and a `dix` package/size diff, and automatically moves conflicting local files aside with a unique `.hm-bak-<timestamp>` suffix.

Useful flags:

- `rebuild --system` (`-s`): rebuild System Manager with paired pre/post snapper snapshots and a `dix` closure diff.
- `rebuild --dry` (`-n`, `--dry-run`): build and preview changes without activating, updating NectarLink, or taking snapshots.
- `rebuild --ask` (`-a`): show the `dix` package diff and ask before activating (Home Manager).
- `rebuild --skip-nectarlink`: skip the NectarLink nightly check for fast or offline rebuilds.
- `rebuild -- <args...>`: forward extra flags (such as `--show-trace` or `--offline`) to the underlying command.
- `rebuild --backup` (`-b`): accepted for compatibility and behaves like `rebuild`.

Every normal Home Manager rebuild attempts to pin the `nectarlink` input to the
newest `v*-nightly.*` release with an APK and checksum before the switch.
NectarLink is a Nix package, so this has to happen before Home Manager
evaluates the configuration. A pending NectarLink transaction is resolved with
the previous updater before the new one is built, so Nix never evaluates a
half-updated flake. The APK queue runs afterwards as an activation hook, with
one marker per device so an offline phone or tablet retries on a later rebuild.
A failed switch attempts to restore the previous pin and Home Manager
generation. See [nectarlink.md](nectarlink.md#nightly-updates).
`rebuild --system` and Nix-on-Droid skip the NectarLink step because it only
exists on the desktop.

Every Home Manager activation also reruns JETLS's Julia app installer against
the upstream `release` ref, so the installed language server follows the latest
published release. This requires network access; if updating fails, the existing
JETLS installation is kept.

Run it after changing anything under `modules/` or `hosts/arch/default.nix`: packages, dotfiles, user services, niri settings, Noctalia, Vicinae.

A logout is usually unnecessary. Log out and back in when changing how the niri session starts, or when the running compositor ignores a config change.

When running Home Manager directly, request backups explicitly to avoid conflicts with existing files:

```bash
home-manager switch --flake .#pseudofractal -b backup
```

`systemd.user.startServices` is `false`, so a switch never starts services itself. Otherwise long oneshots like Lieer full syncs would block activation. The `rebuild` shortcut fills the gap: after a good Home Manager switch it restarts all enabled user timers, so new or changed schedules apply. Restarting a timer only re-arms its schedule, never runs the job, and running syncs are left alone. It also reprints Home Manager's suggested daemon restarts in yellow at the end of a good switch (filtering out timer-driven oneshots and unloaded `stop` hints), instead of leaving them buried in the activation log.

Switched without `rebuild`? Re-arm manually, e.g.:

```bash
systemctl --user restart lieer-iiser.timer lieer-personal.timer email-classify-backfill.timer
```

## System Manager

System Manager owns the SDDM session entry, `/run/system-manager/sw`, `/run/opengl-driver`, and the files declared in `hosts/arch/system.nix`.

Run it after changing `hosts/arch/system.nix` or the `systemConfigs.arch` definition in `flake.nix`:

```bash
system-manager switch --sudo --flake "$PWD#arch"
# or, before system-manager is on PATH:
nix run "$PWD#system-manager" -- switch --sudo --flake "$PWD#arch"
```

Log out and pick **Niri (Nix)** again if the session wrapper or niri package changed. A Home Manager switch doesn't deploy System Manager changes.

Useful checks:

```bash
readlink -f /run/system-manager/sw/bin/niri
readlink -f ~/.nix-profile/bin/niri
niri msg outputs
systemctl --user status noctalia.service
```

Both `readlink` commands should land on the same niri store package.

## Snapshots

`rebuild --system` takes paired snapper `pre`/`post` snapshots of `/`
(`snapper -c root`), kept under number cleanup (default: last 50).
Swap lives in its own `/swap` subvolume so snapshots never trip on it.
Roll back with `sudo snapper -c root undochange <pre-N>..<post-N>`.
Full reference, including rescue scenarios and the rollback caveat: `docs/snapshots.md`.

## Binary caches & garbage collection

The project caches and Nix settings live in `~/.config/nix/nix.conf` (managed by `modules/core/maintenance.nix`) because `accept-flake-config` is off:

```text
extra-substituters = https://cache.numtide.com https://niri-nix.cachix.org https://noctalia.cachix.org https://vicinae.cachix.org
extra-trusted-public-keys = niks3.numtide.com-1:DTx8wZduET09hRmMtKdQDxNNthLQETkc/yaX7M4qK0g= niri-nix.cachix.org-1:SvFtqpDcf7Sm1SMJdby1/+Y+6f3Yt3/3PMcSTKPJNJ0= noctalia.cachix.org-1:pCOR47nnMEo5thcxNDtzWpOxNFQsBRglJzxWPp3dkU4= vicinae.cachix.org-1:1kDrfienkGHPYbkpNj1mWTr7Fm1+zcenzgTizIcI3oc=
```

Without these, Nix builds large packages locally. GitHub API authentication for flake fetches is included via a `0400` sops template (`!include .../nix-access-tokens.conf`) from `modules/core/secrets.nix`.

Weekly user profile cleanup runs via `nh-clean.timer` (`nh clean user --keep 5 --keep-since 7d --optimise`, replacing `nix.gc`), keeping at least 5 generations and everything from the last 7 days.

## Updating inputs

One input at a time:

```bash
nix flake update <name>
git diff flake.lock
```

Never a bare `nix flake update`; name the input. Moving every input at once makes breakage hard to isolate.

Rev-pinned inputs (`nixpkgs-llama`) don't move with `nix flake update`; that command is a no-op on a pinned rev. Bump the rev in `flake.nix`, then re-lock that input.

Some inputs are pinned on purpose:

- `nixpkgs` floats on the unstable branch (the lock file pins the exact rev, so builds stay reproducible). `nixpkgs-llama` stays rev-pinned: bump it by hand to the same rev when you want the CUDA servers rebuilt against the new tree, otherwise routine updates never trigger the from-source CUDA compile.
- `vicinae` must never follow the root nixpkgs. That would rebuild it from source against the wrong libraries (gcc15Stdenv vs system numen GLIBCXX skew) and skip `vicinae.cachix.org`. The input floats on upstream `main` with no override, so its nixpkgs always equals upstream's lock, and every rev's binary is already cached. Updates download instead of compiling. Just `nix flake update vicinae` and build. The flake's `lib` is also needed for `mkVicinaeExtension`, so nixpkgs' own `vicinae` package won't do.
- `niri-nix` provides the overlay both Home Manager and System Manager use. Building niri against the root nixpkgs keeps it compatible with `/run/opengl-driver` (upstream prebuilts silently get zero outputs). Its own nixpkgs input is untouched, so it tracks upstream's lock. Nothing consumed here reads that input (the overlay instantiates with our pkgs; the home module uses `self.lib` plus our `package` override).
- Zotero still bundles Firefox ESR 140, which nixpkgs marks insecure. `modules/graphical/zotero.nix` imports the root nixpkgs with a scoped `permittedInsecurePackages` entry instead of pinning a separate nixpkgs. Update that entry when nixpkgs bumps the bundled ESR.
