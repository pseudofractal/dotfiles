# KDE Connect

KDE Connect runs on non-Android Home Manager setups. Home Manager installs it and runs two user services: `kdeconnect.service` (the daemon) and `kdeconnect-indicator.service` (tray).

Nix-on-Droid doesn't run it; phones and tablets use the Android app as clients.

## Provided tools

- `kdeconnect` ships `kdeconnectd` and `kdeconnect-cli`.
- `glib` ships `gdbus`, used by the Noctalia phone-connect plugin.
- `sshfs` covers optional phone and tablet file browsing.

## Firewall

This repo is standalone Home Manager on Arch, so it doesn't touch the host firewall. Open TCP and UDP `1714-1764` in whatever firewall the Arch host runs.

## Pairing devices

1. Apply the Arch config with `home-manager switch --flake . --impure`.
1. Install and open KDE Connect on the Android phone and tablet.
1. Put the computer and both Android devices on the same reachable network.
1. Pair each device from KDE Connect and accept on both sides.
1. Check both with `kdeconnect-cli --list-devices`.

Test ping, ring, clipboard and file sharing separately per device. File browsing also needs `sshfs` plus SFTP switched on in the Android app.

## Troubleshooting

```bash
systemctl --user status kdeconnect.service kdeconnect-indicator.service
systemctl --user is-active graphical-session.target
systemctl --user is-active tray.target
journalctl --user -u kdeconnect.service -u kdeconnect-indicator.service -b --no-pager
kdeconnect-cli --list-devices
```

If the indicator won't start, the session probably lacks `tray.target`. The daemon and the Noctalia phone widget work without it.
