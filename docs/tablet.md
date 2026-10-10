# Tablet integration

`tablet` with no args prints help. Subcommands:

- `tablet mirror` (`m`): mirror over USB with scrcpy, detached, logging to `~/.local/state/scrcpy.log`. Run it again to stop.
- `tablet input` (`i`): toggles the Sunshine host (detached, `~/.local/state/sunshine.log`). Then drive the laptop from the tablet with Moonlight (client setup is §1.2).
- `tablet files <backend>` (`f`): mount tablet storage and cd into it. `adb` goes over USB through MTP/FUSE at `~/.local/mnt/sierpenski` (go-mtpfs; this host has no gvfs so gio mounting is dead here; needs the `fuse2` system package for `/bin/fusermount`; if the Samsung phone is cabled too it picks by adb serial, otherwise it mounts the only device). `kdeconnect` goes over LAN through SFTP (device `Siérpenski`, needs pairing plus SFTP switched on in the tablet app). `u`/`unmount` detaches everything, `help` reprints this.
- `tablet fa` / `tablet fk`: shortcuts for `files adb` / `files kdeconnect`.

The Arch laptop (niri/Wayland) and the Galaxy Tab S10 Lite share one USB cable in both directions: laptop screen on the tablet as a low-latency stream, tablet screen on the laptop as a mirror. USB first, WiFi as fallback. Everything is declared in `modules/graphical/tablet.nix` and driven by the `tablet` fish function.

## Hardware

| Endpoint | Device | Panel | Aspect |
| -------- | ------ | ----- | ------ |
| Host | Arch laptop, niri, AMD Cezanne iGPU + GTX 1650 Mobile | 1920x1200 (eDP-1) | 16:10 |
| Client | Galaxy Tab S10 Lite (SM-X400), S Pen, 90 Hz TFT | 2112x1320 (WUXGA+) | 16:10 |

Both panels are 16:10, so exact 1:1 input mapping is possible end to end. Pointer drift after setup is config, not physics (see Troubleshooting).

USB tethering shows the tablet as a network gadget (`enp8s0f4u1`). Addresses are static: PC `10.211.109.100/24` (the `tablet-usb` NetworkManager profile), tablet `10.211.109.2`. Ping over the cable is ~1.3 ms, so the network is noise in total latency; what remains is encoder and buffering.

One trap from setup, kept here so it isn't repeated: the first ping test hit `10.211.109.203` and came back 0.04 ms, because that was the PC's own address on the tether interface. Always check `ip -4 addr show <iface>` for which side an address sits on before believing a ping.

## Direction 1: laptop screen on the tablet

Two servers were tried. Both lived in the module for a while; one survived.

### 1.1 Weylus (tried, removed)

Weylus serves a browser page that grabs PointerEvents (mouse, touch, stylus with pressure and tilt) and replays them on the host through Linux uinput, while the host screen comes back as fragmented MP4 over a websocket. Its one standout is pressure-sensitive stylus forwarding. Nothing else tested does that.

It was removed for two reasons that stack:

- Latency. Software x264 plus browser-side buffering gives 200–500 ms glass-to-glass on WiFi, ~80–150 ms over USB. No low-latency mode exists; the floor is structural.
- Fragile transport. The server speaks plain HTTP on port 1701 with a websocket on 9001. Mobile browsers keep auto-upgrading to HTTPS, and the server answers the TLS bytes with `invalid HTTP method parsed`. Packets flow fine over the cable while the connection dies opaquely.

Weylus is still the only software route to pen pressure. If pressure ever outranks latency, bring it back: over USB tethering, at the tether IP, hardware encoding on.

### 1.2 Sunshine + Moonlight (kept)

Sunshine speaks the NVIDIA GameStream protocol: hardware-encoded H.264/HEVC out, with touch, mouse, keyboard and stylus back (absolute, no pressure). Glass-to-glass is about a frame, 10–30 ms.

The encoder choice bites, so here it is plainly. The nixpkgs Sunshine build ships no CUDA (`Cannot load libcuda.so.1`; the nvenc trial in the startup log dies), so the GTX 1650's NVENC is out of reach from this package even though it would be the better encoder. What works is `h264_vaapi` on the AMD iGPU, clean through the world-readable render nodes. The `amdgpu_cs_ctx_create2 failed (-13)` and `CAP_SYS_ADMIN` lines in the startup log are noise. Sunshine falls back to portal capture, which already lists `eDP-1` at 1920x1200. Joining the `video` group silences them and opens the direct-DRM path.

#### Host setup

1. `rebuild` to install `sunshine`.
2. `sudo usermod -aG video $USER`, then log out and back in (capture permissions; groups apply to new sessions only).
3. If ufw is active: `sudo ufw allow 47984:48010/tcp` and `sudo ufw allow 47998:48010/udp`. Inactive by default on Arch.
4. Run `sunshine`, open `https://localhost:47990` (accept the self-signed certificate), create credentials, and pick the VAAPI encoder under Configuration → Audio/Video.
5. The stream is unencrypted by design (latency beats confidentiality here): trusted networks and USB only, never forward these ports on a router.

#### Client setup (Moonlight, Play Store, free)

1. Cable the tablet with USB tethering on. The PC side is the static `10.211.109.100`; check with `ip -4 -brief addr show enp8s0f4u1`.
2. Moonlight → Add Host Manually → `10.211.109.100` → enter the shown PIN in Sunshine's web UI (PIN page). Pairing is permanent.
3. Tap the desktop entry to stream.

#### Pairing hygiene (read before re-pairing)

Every PIN round appends a row to `named_devices` in `~/.config/sunshine/sunshine_state.json`, even for an already-known certificate. Duplicate rows poison the trust store: from the second identical row on, no client verifies and every stream 401s with `The client is not authorized`, while pairing keeps reporting success and stacking more rows (upstream [LizardByte/Sunshine#5696](https://github.com/LizardByte/Sunshine/issues/5696)). Restarts never fix it; only an empty store does. So pair exactly once, then never delete/re-add the host or enter PINs "just to be sure". Restarts, IP changes and client updates don't break pairing. If a 401 ever comes back, count duplicate certs first. Recovery is stop the server, back up the state file, empty `named_devices`, start, one single fast round. `tablet input` warns at startup when duplicates exist.

#### Client settings

- Resolution: native (or 1920x1200). Moonlight defaults to 720p/1080p (16:9). A 16:10 desktop streamed at 16:9 skews vertically, and every touch coordinate with it. Matching aspect is the biggest mapping fix there is. Check with the corner test: tap each tablet corner, the cursor must jump to the matching host corner.
- Touchscreen-as-trackpad: OFF. ON means relative mode (drags push the cursor); OFF means absolute (a tap jumps). A Moonlight bug hides this toggle on some Samsung devices. Update the app; if it's still missing, use the S Pen, whose passthrough is always absolute and ignores the toggle.
- Gestures: two-finger tap is right-click, two-finger drag is scroll. Without these it's a demo; with them it's usable.
- Audio goes to the tablet by default. Send it back to the host or mute unless tablet audio is wanted.
- Bitrate: raise it over USB, headroom is free sharpness. Stay on H.264 for lowest latency.
- Turn on the performance overlay so latency is a number (network + decode), not a feeling.
- Stay awake: the tablet is the display, so a sleeping tablet drops the session. Developer options → "Stay awake" keeps the screen lit while cabled; normal timeouts resume on unplug.

#### Palm rejection

There is none, on either side, and there can't be: the protocol carries pointer positions, so by the time a palm reaches the host it's indistinguishable from a finger. What helps, best first: set the drawing app so touch pans/zooms and only the pen draws (Krita → Canvas Input Settings); wear a two-finger artist glove; hover the palm (the S Pen reads hover from a generous distance).

## Direction 2: tablet screen on the laptop

`scrcpy` (plus `android-tools`) mirrors and controls the tablet over the same cable at ~35–70 ms, with tablet audio forwarded (`--no-audio` silences it). One-time device setup: tap Build number 7× → Developer options → USB debugging ON → accept the RSA prompt (tick "always allow"). If no prompt appears, turn USB tethering off first (the network gadget mode can crowd out the adb channel), then revoke authorizations, restart the adb server, and replug.

The `tablet` fish function wraps the lifecycle as a toggle:

- First run waits for an authorized device, then launches scrcpy detached (`--window-title="Tablet"`, output to `~/.local/state/scrcpy.log`) and frees the terminal right away.
- Second run SIGTERMs scrcpy (clean device-side teardown), waits up to 5 s, and escalates to `kill -9` only if stuck.

Extra scrcpy flags pass through (`tablet --no-audio`). `--turn-screen-off` works per invocation but stays off by default on purpose.

## Window management

The aspect match is used in niri (`modules/desktop/niri/rules.nix`):

- A rule on `title = "Tablet"` (set by the `tablet` function itself, so it holds whatever the device model is, unlike the default `SM-X400` title) forces `open-fullscreen` with no exceptions.
- `tablet-mirror.desktop` (`modules/graphical/tablet.nix`) ties the scrcpy window (`StartupWMClass=.scrcpy-wrapped`) to the Adwaita `phone` icon. Same trick as the nchat/WhatsApp logo (`Mod+C` spawns kitty with `--app-id=nchat`, whose desktop entry carries the WhatsApp SVG). The filename stays distinct so it never clashes with upstream's `scrcpy.desktop`.

Manual override for any window: `Mod+Ctrl+F` toggles fullscreen, `Mod+Shift+F` maximizes to edges, `Mod+F` maximizes the column.

## Files in play

| Path | Role |
| ---- | ---- |
| `modules/graphical/tablet.nix` | `sunshine`, `scrcpy`, `android-tools` packages; `tablet-mirror.desktop` entry |
| `modules/core/fish/functions/tablet.fish` | toggle lifecycle for the mirror session |
| `modules/desktop/niri/rules.nix` | fullscreen rule for the `Tablet` window |
| `modules/graphical/default.nix` | imports `tablet.nix` |

## Troubleshooting

| Symptom | Cause / fix |
| ------- | ----------- |
| Weylus: `invalid HTTP method parsed` from tablet IP | Browser auto-upgraded to HTTPS; use explicit `http://`, disable the browser's secure-upgrade toggle |
| Weylus QR unusable | It encodes the WiFi URL; type the tether URL manually |
| Sunshine Capture dropdown empty | Port 9001/websocket blocked, or portal screencast denied on the host |
| `Failed to create uinput device` (Weylus) | User not in `uinput` group in this session; log out/in |
| `amdgpu_cs_ctx_create2 failed`, `CAP_SYS_ADMIN` (Sunshine) | Benign; add `video` group for the direct-DRM path |
| No adb RSA prompt | Disable USB tethering, revoke authorizations, `adb kill-server`, replug |
| Tablet sleeps mid-stream | Developer options → "Stay awake" (charging = cabled) |
| Pointer drift after setup change | Re-check stream aspect (native/1920x1200) and trackpad toggle; run the corner test |
