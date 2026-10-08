# Tablet Integration

Bidirectional integration between the Arch laptop (niri/Wayland) and the
Samsung Galaxy Tab S10 Lite over a USB cable: the laptop drives the tablet
as a low-latency screen, and the tablet drives the laptop as a mirrored
display. USB is the primary transport; WiFi is a fallback. All components
are declared in `modules/graphical/tablet.nix` and driven by the `tablet`
fish function.

## Hardware and Topology

| Endpoint | Device | Panel | Aspect |
| -------- | ------ | ----- | ------ |
| Host | Arch laptop, niri, AMD Cezanne iGPU + GTX 1650 Mobile | 1920x1200 (eDP-1) | 16:10 |
| Client | Galaxy Tab S10 Lite (SM-X400), S Pen, 90 Hz TFT | 2112x1320 (WUXGA+) | 16:10 |

Both panels are 16:10, so a geometrically exact 1:1 input mapping is
achievable end to end — any pointer drift is configuration, not physics
(see §5).

USB tethering presents the tablet as a network gadget (`enp8s0f4u1`).
Observed addressing on this link: PC at `10.211.109.203/24`, tablet as
gateway at `10.211.109.2`. Measured round-trip latency over the cable is
~1.3 ms, i.e. the network contributes negligibly to total system latency;
everything above that floor is encoder and buffering delay.

A methodological caution from bringing this up: the first ping test
targeted `10.211.109.203` and returned 0.04 ms — because that is the PC's
own address on the tether interface. Always confirm with
`ip -4 addr show <iface>` which side of the link an address belongs to
before drawing conclusions from it.

## Direction 1: Laptop Screen on the Tablet

Two servers were evaluated. Both were kept in the module for a time; only
the winner remains.

### 1.1 Weylus (evaluated, removed)

Weylus serves a browser page that captures PointerEvents (mouse, touch,
stylus with pressure and tilt) and replays them on the host through Linux
uinput devices, while the host screen is returned as a fragmented-MP4
stream over a websocket. Its distinguishing capability is pressure-
sensitive stylus forwarding — unique among the options tested.

It was removed for two compounding reasons:

- **Latency architecture.** Software x264 encoding plus browser-side
  buffering yields 200–500 ms glass-to-glass on WiFi and ~80–150 ms over
  USB. The pipeline has no low-latency mode; the floor is structural.
- **Transport fragility.** The server speaks plain HTTP on port 1701 with
  a websocket on 9001. Mobile browsers increasingly auto-upgrade to HTTPS,
  whose TLS handshake bytes the server rejects with `invalid HTTP method
  parsed`. The connection then fails opaquely despite packets flowing
  correctly over the cable.

Weylus remains the only software path that forwards pen pressure. If
pressure-sensitive drawing ever outranks latency, it should be revisited —
over USB tethering, at the tablet's tether IP, with hardware encoding
enabled.

### 1.2 Sunshine + Moonlight (adopted)

Sunshine implements the NVIDIA GameStream protocol: a hardware-encoded
H.264/HEVC stream with a back-channel for touch, mouse, keyboard, and
(absolute, pressure-less) stylus input. Typical glass-to-glass latency is
one frame (~10–30 ms).

Encoder selection deserves an explicit note. The nixpkgs Sunshine build
contains no CUDA support (`Cannot load libcuda.so.1`; the nvenc trial in
the startup log fails), so the GTX 1650's NVENC is unreachable from this
package despite being the theoretically superior encoder. The working
encoder is `h264_vaapi` on the AMD iGPU, which initializes cleanly through
the world-accessible render nodes. The `amdgpu_cs_ctx_create2 failed
(-13)` and `CAP_SYS_ADMIN` lines in the startup log are benign: Sunshine
falls back to portal-based capture, which already enumerates `eDP-1` at
1920x1200. Membership in the `video` group quiets them and enables the
direct-DRM path.

#### Host setup

1. `rebuild` to install `sunshine`.
2. `sudo usermod -aG video $USER`, then log out and back in (capture
   permissions; groups apply to new sessions only).
3. If ufw is active: `sudo ufw allow 47984:48010/tcp` and
   `sudo ufw allow 47998:48010/udp`. Inactive by default on Arch.
4. Run `sunshine`, open `https://localhost:47990` (accept the self-signed
   certificate), create credentials, and select the VAAPI encoder under
   Configuration → Audio/Video.
5. The service is unencrypted by design (latency over confidentiality):
   trusted networks and USB only, never forward these ports on a router.

#### Client setup (Moonlight, Play Store, free)

1. USB-cable the tablet, enable USB tethering, and note the PC's tether
   IP (`ip -4 -brief addr show`).
2. Moonlight → Add Host Manually → tether IP → enter the shown PIN in
   Sunshine's web UI (PIN page). Pairing is permanent.
3. Tap the desktop entry to stream.

#### Client settings that matter

- **Resolution → native (or 1920x1200).** Moonlight defaults to 720p/1080p
  (16:9). Streaming a 16:10 desktop at 16:9 vertically skews the image and
  with it every touch coordinate. Matching aspect ratios is the single
  largest mapping fix; verify with the corner test (tap each tablet corner,
  cursor must teleport to the matching host corner).
- **"Touchscreen as trackpad" → OFF.** ON is relative/trackpad mode (drags
  push the cursor); OFF is absolute mode (tap = jump). A known Moonlight
  bug hides this toggle on some Samsung devices — update the app, and if
  it is still absent, use the S Pen, whose native passthrough is always
  absolute and ignores the toggle.
- **Gestures:** two-finger tap = right-click, two-finger drag = scroll.
  These two make desktop use viable; without them it is a demo.
- **Audio:** streams to the tablet by default; redirect to the host or
  mute unless tablet audio is wanted.
- **Bitrate:** raise over USB (headroom is free sharpness); keep H.264 for
  minimum latency.
- **Observability:** enable the performance-stats overlay so latency is a
  number (network + decode) rather than a feeling.
- **Stay-awake:** the tablet is the display — a sleeping tablet drops the
  session. Developer options → "Stay awake" keeps the screen lit while
  cabled; normal timeouts resume on unplug.

#### Palm rejection

There is none, on either side, and there cannot be: the stream protocol
carries pointer positions, so a palm is indistinguishable from a finger by
the time it reaches the host. Mitigations in descending effectiveness:
configure the drawing application so touch pans/zooms while only the pen
draws (Krita → Canvas Input Settings); wear a two-finger artist glove;
keep the palm hovering (the S Pen's hover range is generous).

## Direction 2: Tablet Screen on the Laptop

`scrcpy` (plus `android-tools`) mirrors and controls the tablet over the
same cable at ~35–70 ms, with tablet audio forwarded (`--no-audio`
silences it). One-time device setup: tap Build number 7× → Developer
options → USB debugging ON → accept the RSA prompt (tick "always allow").
If no prompt appears, turn USB tethering off first — the network gadget
mode can crowd out the adb channel — then revoke authorizations, restart
the adb server, and replug.

The `tablet` fish function wraps the lifecycle as a toggle:

- First invocation waits for an authorized device, then launches scrcpy
  detached (`--window-title="Tablet"`, output to
  `~/.local/state/scrcpy.log`) and frees the terminal immediately.
- Second invocation SIGTERMs scrcpy (clean device-side teardown), waits up
  to 5 s, and escalates to `kill -9` only if stuck.

Extra scrcpy flags pass through (`tablet --no-audio`). `--turn-screen-off`
is available per-invocation but deliberately not the default.

## Window Management

The aspect-ratio match is exploited in niri (`modules/desktop/niri/rules.nix`):

- A window rule matching `title = "Tablet"` (set deterministically by the
  `tablet` function, independent of device model, unlike the default
  `SM-X400` title) forces `open-fullscreen` with no exceptions.
- `tablet-mirror.desktop` (`modules/graphical/tablet.nix`) binds the
  scrcpy window (`StartupWMClass=.scrcpy-wrapped`) to the Adwaita `phone`
  icon — the same mechanism as the nchat/WhatsApp logo (`Mod+C` spawns
  kitty with `--app-id=nchat`, whose desktop entry carries the WhatsApp
  SVG). A distinct desktop filename avoids clashing with the `scrcpy.desktop`
  shipped upstream.

Manual override for any window: `Mod+Ctrl+F` toggles fullscreen,
`Mod+Shift+F` maximizes to edges, `Mod+F` maximizes the column.

## Repository Map

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
