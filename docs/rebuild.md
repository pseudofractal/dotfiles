# Rebuild notes

Run from the repo root. Both commands pick up uncommitted changes, so a clean tree isn't needed.

## Home Manager

The normal rebuild:

```bash
home-manager switch --flake .#pseudofractal
```

The fish shortcut is `rebuild`. `rebuild --system` does System Manager, `rebuild --backup` tells Home Manager to move an existing file aside instead of refusing.

Run it after changing anything under `modules/` or `hosts/arch/default.nix`: packages, dotfiles, user services, niri settings, Noctalia, Vicinae.

A logout is usually unnecessary. Log out and back in when changing how the niri session starts, or when the running compositor ignores a config change.

If Home Manager refuses to replace an existing file, keep a backup during the switch:

```bash
home-manager switch --flake .#pseudofractal -b backup
```

`systemd.user.startServices` is `false`, so a switch never starts services itself. Otherwise long oneshots like Lieer full syncs would block activation. The `rebuild` shortcut fills the gap: after a good Home Manager switch it restarts all user timers, so new or changed schedules apply. Restarting a timer only re-arms its schedule, never runs the job, and running syncs are left alone. It also reprints Home Manager's suggested service restarts in yellow at the end of a good switch, instead of leaving them buried in the activation log.

Switched without `rebuild`? Re-arm manually, e.g.:

```bash
systemctl --user restart lieer-iiser.timer lieer-personal.timer email-classify-backfill.timer
```

## System Manager

System Manager owns the SDDM session entry, `/run/system-manager/sw`, `/run/opengl-driver`, and the files declared in `hosts/arch/system.nix`.

Run it after changing `hosts/arch/system.nix` or the `systemConfigs.arch` definition in `flake.nix`:

```bash
nix run 'github:numtide/system-manager' -- switch --sudo --flake "$PWD#arch"
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

## Binary caches

The project caches live in `~/.config/nix/nix.conf` because `accept-flake-config` is off:

```text
extra-substituters = https://niri-nix.cachix.org https://noctalia.cachix.org https://vicinae.cachix.org
extra-trusted-public-keys = niri-nix.cachix.org-1:SvFtqpDcf7Sm1SMJdby1/+Y+6f3Yt3/3PMcSTKPJNJ0= noctalia.cachix.org-1:pCOR47nnMEo5thcxNDtzWpOxNFQsBRglJzxWPp3dkU4= vicinae.cachix.org-1:1kDrfienkGHPYbkpNj1mWTr7Fm1+zcenzgTizIcI3oc=
```

Without these, Nix builds large packages locally.

## Updating inputs

One input at a time:

```bash
nix flake lock --update-input <name>
git diff flake.lock
```

Never a bare `nix flake update`. Moving every input at once makes breakage hard to isolate.

Rev-pinned inputs (`nixpkgs`, `nixpkgs-llama`, `nixpkgs-zotero`) don't move with `lock --update-input`; that command is a no-op on a pinned rev. Bump the rev in `flake.nix`, then re-lock that input.

Some inputs are pinned on purpose:

- `nixpkgs` itself is pinned to a channel-tip rev (not the moving branch), so every machine builds the same tree. `nixpkgs-llama` rides the same rev, which keeps one shared nixpkgs checkout for the CUDA build below.
- `vicinae` must never follow the root nixpkgs. That would rebuild it from source against the wrong libraries (gcc15Stdenv vs system numen GLIBCXX skew) and skip `vicinae.cachix.org`. The input floats on upstream `main` with no override, so its nixpkgs always equals upstream's lock, and every rev's binary is already cached. Updates download instead of compiling. Just `nix flake lock --update-input vicinae` (deprecated alias: `nix flake update vicinae`) and build. The flake's `lib` is also needed for `mkVicinaeExtension`, so nixpkgs' own `vicinae` package won't do.
- `niri-nix` provides the overlay both Home Manager and System Manager use. Building niri against the root nixpkgs keeps it compatible with `/run/opengl-driver` (upstream prebuilts silently get zero outputs). Its own nixpkgs input is untouched, so it tracks upstream's lock. Nothing consumed here reads that input (the overlay instantiates with our pkgs; the home module uses `self.lib` plus our `package` override).
- `nixpkgs-zotero` holds Zotero 10.0.2 on a compatible Firefox ESR (the last nixpkgs shipping firefox-esr-140; Zotero's build scripts die against ESR 153's ActorManagerParent). Temporary until upstream adapts Zotero.
- `nixpkgs-llama` freezes both llama.cpp servers, so routine nixpkgs updates never trigger a from-source CUDA rebuild.
