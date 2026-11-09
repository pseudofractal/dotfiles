# NectarLink

NectarLink is an Android \<-> PC companion app: notifications, messages, calls,
clipboard, files, screen mirroring, app windows, webcam/mic and more. It runs
alongside KDE Connect; this repo installs it from the upstream flake, pinned to
the release that matches the Android APK.

## What this repo installs

- `modules/core/nectarlink.nix` installs `nectarlink-desktop` plus the runtime
  helpers `wl-clipboard`, `xclip` and `xdg-utils`. FUSE comes from the host's
  setuid `fusermount3`.
- A user service starts it in the tray at login:
  `systemctl --user status nectarlink.service`.
- `flake.nix` pins the input to `github:thtbee/nectarlink/v0.1.5`.

## Android APK

Download the matching release and verify it:

<https://github.com/thtbee/nectarlink/releases/download/v0.1.5/Nectarlink-0.1.5-android.apk>

```text
df48e7fe059569fcfd2a38799b828fa4005af2e53b7c1c76fa81d077922df4b6
```

Sideload it. Android may block notification access for apps installed from a
file: **Settings -> Apps -> NectarLink -> three dots -> Allow restricted
settings**, then enable notification access.

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

The flake input is pinned to v0.1.5. `modules/core/nectarlink.nix` carries two
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
- Keep KDE Connect installed as the fallback while NectarLink is early beta.

## Disable or remove

```bash
systemctl --user disable --now nectarlink.service
```

Then remove `./nectarlink.nix` from `modules/core/default.nix` and the
`nectarlink` input from `flake.nix`, and rebuild.
