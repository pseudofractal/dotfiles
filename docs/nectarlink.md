# NectarLink

NectarLink is an Android \<-> PC companion app: notifications, messages, calls,
clipboard, files, screen mirroring, app windows, webcam/mic and more. This repo
installs it from the upstream flake and pins a release tag. Nightly rebuilds
advance that pin and queue the matching APK.

## What this repo installs

- `modules/core/nectarlink.nix` installs `nectarlink-desktop`, the
  `nectarlink-nightly` updater app, plus the runtime helpers `wl-clipboard`,
  `xclip` and `xdg-utils`. FUSE comes from the host's setuid `fusermount3`.
- A user service starts it in the tray at login:
  `systemctl --user status nectarlink.service`.
- `flake.nix` pins the input to the tag the nightly updater advances.

## Optional stable APK

The nightly flow below downloads its own APK. To sideload the older stable
release manually instead, download and verify it:

<https://github.com/thtbee/nectarlink/releases/download/v0.1.5/Nectarlink-0.1.5-android.apk>

```text
df48e7fe059569fcfd2a38799b828fa4005af2e53b7c1c76fa81d077922df4b6
```

Sideload it. Android may block notification access for apps installed from a
file: **Settings -> Apps -> NectarLink -> three dots -> Allow restricted
settings**, then enable notification access.

## Nightly updates

Every normal Home Manager `rebuild` attempts to update NectarLink before the switch:

1. Recover any pending transaction with the previously built updater before
   evaluating the repo, so an interrupted pin/lock pair is repaired without
   asking Nix to read it.
1. Resolve the newest nightly tag with a complete release, download its APK,
   and verify it against the published checksum before anything is pinned.
   Tags with missing assets are skipped; a network failure stops the update
   instead of silently pinning an older tag.
1. Save a transaction with the old files and their hashes, rewrite the input
   atomically, record the new flake hash, run
   `nix flake update nectarlink`, record the new lock hash, and mark the
   transaction locked. While the lock is being rewritten, a crash leaves
   enough state to restore the old lock.
1. Run the normal `home-manager switch`. A successful switch marks the
   transaction switched. On failure, restore each flake file that still matches
   its old or new hash, attempt to roll back the Home Manager generation, and
   clear queued markers for the failed tag. A retry after an interrupted
   rollback finishes the remaining files. A transaction from a moved checkout
   is adopted only when both flake files match; an incomplete transaction is
   discarded.
1. After a successful switch, `home.activation.updateNectarlinkApk` queues the
   APK for each online Android device that has not been queued for that tag yet.
   The marker is per device, so an offline device retries on a later rebuild
   without resending to the other one.

```bash
rebuild                 # update NectarLink nightly, switch, queue APK
```

The update/queue logic lives in the flake app
`nix run .#nectarlink-nightly` (defined in `tools/nectarlink-nightly.nix`).
`rebuild` calls `recover`, `update`, `has-pending`, `mark-switched`, and
`commit`/`rollback`; the activation hook calls `send --pending`. The app is
useful on its own:

```bash
nix run .#nectarlink-nightly -- latest        # newest nightly with assets
nix run .#nectarlink-nightly -- pinned        # tag in flake.nix
nix run .#nectarlink-nightly -- update        # pin + re-lock
nix run .#nectarlink-nightly -- recover       # resolve a pending transaction
nix run .#nectarlink-nightly -- status        # pin, latest, per-device state
nix run .#nectarlink-nightly -- send          # queue the pinned tag's APK
nix run .#nectarlink-nightly -- send --pending
nix run .#nectarlink-nightly -- send --dry-run
nix run .#nectarlink-nightly -- has-pending   # exit 0 with a pending transaction
nix run .#nectarlink-nightly -- mark-switched # record a successful switch
nix run .#nectarlink-nightly -- commit        # finish a switched transaction
nix run .#nectarlink-nightly -- rollback      # restore an unswitched pin
nix run .#nectarlink-nightly -- rollback --clear-queued
```

For an interrupted rebuild, run `rebuild` or the installed/rooted
`nectarlink-nightly`; `nix run` evaluates the flake and is not a reliable
recovery path while the checkout is half-updated.

- Per-device queue markers live in
  `~/.local/state/nectarlink-nightly/queued/<tag>/<device-id>`. A device that
  was offline is queued on the next `rebuild`.
- `send --pending` skips devices already queued for the tag; `send` without
  `--pending` queues for every online device. `--dry-run` never locks,
  downloads, or writes state; it reads the local API for target names and
  falls back to the tag when the API is unavailable. `--mark-queued` marks
  manual queues.
- `latest` and a real `update` exit 1 with an explicit message when GitHub
  cannot be reached. `update` exits 3 when the pin is already current, or 5
  when recovery committed a previously switched transaction and the pin stayed
  current. `send` exits 4 when it is deferred (offline devices, unavailable
  API, or no targets); the activation hook treats that as “retry later”, not
  as a failed switch.
- The whole rebuild is serialized with `flock`, and direct
  `update`/`mark-switched`/`commit`/`rollback`/`send` commands use the same
  lock. The rebuild child carries an internal guard so nested app calls do not
  re-lock. State migration also runs under that lock. `has-pending`, `status`,
  `latest`, `update --dry-run`, and `send --dry-run` use no lock.
  `update --dry-run` still checks release metadata on GitHub, while
  `send --dry-run` reads the local API; neither migrates state or writes
  markers. `pinned` also uses no lock.
- A transaction is restored only when each file still matches its recorded old
  or new hash. A switched transaction is committed by the next `update`; a
  manual `rollback` refuses it unless `--allow-switched` is given after
  `home-manager switch --rollback`. An unswitched transaction whose flake no
  longer matches is retained for inspection instead of overwriting unrelated
  edits; a switched transaction with a changed pin is discarded. Interrupted
  updates are recovered before the update contacts GitHub, and `status` shows a
  pending transaction for this checkout.
- After a successful switch, `rebuild` restarts `nectarlink.service` when an
  update was applied, the binary changed, or a switched update was recovered.
  A failed restart is recorded and retried on the next rebuild. `try-restart`
  means a stopped service stays stopped.
- `rebuild --system` and Nix-on-Droid skip the NectarLink step. A direct
  `home-manager switch` still queues the APK for the currently pinned tag, but
  it does not move the nightly pin; use `rebuild` for that. After a manual
  `update` plus switch, run `mark-switched` and then `commit`, and restart the
  service with `systemctl --user try-restart nectarlink.service`. The activation
  hook skips if `nectarlink.service` is not active or Home Manager is doing a
  dry run; if it cannot query the service it warns and tries the queue anyway.
- The APK is queued to the device; Android saves it in Downloads and asks for
  permission to install unknown apps the first time.
- NectarLink's local API must be enabled in **Settings -> Local automation API**
  (it is on in this setup; see `~/.local/share/Nectarlink/api-token.json`).

The link and hash above are the older stable `v0.1.5` sideload, not the
currently pinned nightly. The nightly updater downloads and verifies the
matching nightly APK itself; those values are not used for nightly updates.

## Pairing

1. Start NectarLink on the PC (or `systemctl --user start nectarlink.service`).
1. Scan the QR code with the phone, or pick the PC from nearby devices and
   compare the 6-digit code on both screens.
1. Enable only the features you want. Sensitive features are off by default.

## Firewall

This repo is standalone Home Manager on Arch, so it does not touch the host
firewall. NectarLink needs these ports from the local network only:

- TCP and UDP `7718` (the upstream default data port)
- TCP and UDP `53317` (LocalSend)
- UDP `5353` (mDNS)

The QUIC port is chosen at start and written to
`~/.local/share/Nectarlink/port`; 7718 is the upstream default. The app's
Connection Doctor reads the actual port and can open it.

UFW:

```bash
for net in 192.168.0.0/16 10.0.0.0/8 172.16.0.0/12 fe80::/10; do
  for port in 7718 53317; do
    sudo ufw allow from "$net" to any port "$port" proto tcp
    sudo ufw allow from "$net" to any port "$port" proto udp
  done
  sudo ufw allow from "$net" to any port 5353 proto udp
done
```

firewalld:

```bash
add_firewalld_rule() {
  sudo firewall-cmd --permanent --add-rich-rule="rule family=\"$1\" source address=\"$2\" port port=\"$3\" protocol=\"$4\" accept"
}

for net in 192.168.0.0/16 10.0.0.0/8 172.16.0.0/12; do
  for port in 7718 53317; do
    add_firewalld_rule ipv4 "$net" "$port" tcp
    add_firewalld_rule ipv4 "$net" "$port" udp
  done
  add_firewalld_rule ipv4 "$net" 5353 udp
done
for port in 7718 53317; do
  add_firewalld_rule ipv6 fe80::/10 "$port" tcp
  add_firewalld_rule ipv6 fe80::/10 "$port" udp
done
add_firewalld_rule ipv6 fe80::/10 5353 udp
sudo firewall-cmd --reload
```

If discovery still fails, make sure mDNS is running:

```bash
sudo systemctl enable --now avahi-daemon
```

## Optional: phone as webcam

This needs the `v4l2loopback` kernel module. On Arch with the Zen kernel:

```bash
sudo pacman -S v4l2loopback-dkms linux-zen-headers
echo v4l2loopback | sudo tee /etc/modules-load.d/nectarlink-vcam.conf
echo 'options v4l2loopback exclusive_caps=1 card_label="NectarLink Webcam"' |
  sudo tee /etc/modprobe.d/nectarlink-vcam.conf
sudo modprobe v4l2loopback exclusive_caps=1 card_label="NectarLink Webcam"
```

Phone storage in the file manager uses FUSE, which is already installed.

## Optional: Elevated

**Settings -> Permissions -> Control from your PC -> Real touch and keys** sets
up the shell-level helper through Wireless Debugging, Shizuku or root. It is
what enables real touch dragging, app windows, background phone-to-PC clipboard
sync and sensitive OTP notifications on Android 15+.

Without Elevated, notifications, SMS, files, PC-to-phone clipboard and
view-only mirroring still work. Start at Standard and only enable Elevated if
you need those features; banking apps may detect it. NectarLink has a **Pause
for banking apps** setting for that.

## Niri

The Island is a floating `Qt.Tool` window. `modules/desktop/niri/rules.nix`
matches its title (`Nectar Island` on XWayland, `Nectar Island - PiP` on native
Wayland), floats it, and pins it to top-center. On the 1920x1200 output that is
`x=760 y=8`; Niri measures from the work area, so it lands 8px below the 40px
Noctalia bar.

## Nix package notes

The flake input is pinned to the tag in `flake.nix`; the nightly updater
advances it. `modules/core/nectarlink.nix` carries two
Nix-specific fixes:

- `nectarlink-app-id.patch` sets `QGuiApplication::setDesktopFileName` before
  `QApplication` is constructed. Upstream sets it afterwards, so Wayland gives
  the window an empty app-id and Noctalia shows a generic taskbar icon.
- A `postFixup` adds FFmpeg 9, FFmpeg 8 and OpenH264 to the wrapped binaries'
  `RUNPATH`. `wrapQtAppsHook` overwrites the package's `preFixup` RPATH; FFmpeg 9
  is what the C++ HEVC encoder was built against, FFmpeg 8 is the newest ABI the
  Rust H.264 decoder understands, and OpenH264 is the H.264 encoder fallback.

The app's self-updater is turned off in its settings because Nix owns the
version. Re-check both fixes when bumping the pinned release.

## Caveats

- On Linux the device key and clipboard history are protected only by `0600`
  file permissions, not a keystore. Use full-disk encryption; upstream PR
  [#189](https://github.com/thtbee/nectarlink/pull/189) adds Secret Service
  support.
- On Wayland, clipboard access may only work while NectarLink's window has
  focus, depending on the compositor/portal. KDE Plasma and X11 sync in the
  background.

## Disable or remove

```bash
systemctl --user disable --now nectarlink.service
```

Then remove `./nectarlink.nix` from `modules/core/default.nix` and the
`nectarlink` input from `flake.nix`, and rebuild.
