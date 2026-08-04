# KDE Connect

KDE Connect is enabled for non-Android Home Manager configurations. Home Manager installs KDE Connect and manages the following user services:

- `kdeconnect.service` runs the daemon.
- `kdeconnect-indicator.service` provides tray integration.

The Nix-on-Droid configuration does not run KDE Connect. Android phones and tablets should use the KDE Connect Android app as clients.

## Provided tools

- `kdeconnect` provides `kdeconnectd` and `kdeconnect-cli`.
- `glib` provides `gdbus`, used by the Noctalia phone-connect plugin.
- `sshfs` enables optional phone and tablet file browsing.

## Firewall

This repository uses standalone Home Manager on Arch, so it does not manage the host firewall. Allow TCP and UDP ports `1714-1764` in the firewall configured on the Arch host.

## Pairing devices

1. Apply the Arch configuration with `home-manager switch --flake . --impure`.
1. Install and open KDE Connect on the Android phone and tablet.
1. Put the computer and both Android devices on the same reachable network.
1. Pair each device from KDE Connect and accept the request on both sides.
1. Check both devices with `kdeconnect-cli --list-devices`.

Test ping, ring, clipboard, and file sharing independently for each device. File browsing additionally requires `sshfs` and the KDE Connect SFTP feature to be enabled on the Android device.

## Troubleshooting

```bash
systemctl --user status kdeconnect.service kdeconnect-indicator.service
systemctl --user is-active graphical-session.target
systemctl --user is-active tray.target
journalctl --user -u kdeconnect.service -u kdeconnect-indicator.service -b --no-pager
kdeconnect-cli --list-devices
```

If the indicator does not start, the desktop session may not provide `tray.target`; the daemon and Noctalia phone widget can still work independently.
