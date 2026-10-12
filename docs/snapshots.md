# Snapshots

Btrfs snapshots of `/` via snapper, taken automatically before every
`rebuild --system`. File-level revert is the normal rescue path; full
rollback is possible with one caveat (see below).

## Layout

```
/                       /dev/nvme0n1p2[/@]            subvolid=256, subvol=/@
/.snapshots             /dev/nvme0n1p2[/@.snapshots]  subvolid=260, subvol=/@.snapshots
/home                   /dev/nvme0n1p2[/@home]        subvolid=257, subvol=/@home
/var/log                /dev/nvme0n1p2[/@log]        subvolid=258, subvol=/@log
/var/cache/pacman/pkg   /dev/nvme0n1p2[/@pkg]        subvolid=259, subvol=/@pkg
/swap                   nested subvolume inside @ (swapfile lives here)
```

A root snapshot covers `@` only. That includes `/etc`, `/nix`, and the
system-manager profile links, but excludes `/home`, `/var/log`, the pacman
cache, and swap. Rolling back `/` never touches personal data, and logs
survive a rollback for forensics.

`/.snapshots` is a dedicated subvolume mounted from fstab, not a directory
inside `@`. Snapshots of `/` therefore cannot recurse into themselves, and
a rollback of `@` cannot wipe snapshot history. This is the openSUSE-style
layout; the subvolume predates snapper itself (installer created it in 2024)
and was adopted rather than recreated.

Swap lives in nested `/swap` because btrfs refuses to snapshot a subvolume
containing an active swapfile (`errno 26, Text file busy`). The directory
has NOCOW set (`chattr +C`) before the swapfile is created, which btrfs
requires. The file is 32 GiB against 15 GiB RAM, so hibernate keeps working.

## Automatic snapshots

`rebuild --system` (in `modules/core/fish/functions/rebuild.fish`) creates
a snapshot before switching, and continues with a warning if it fails:

```fish
sudo snapper -c root create --description "pre-rebuild <timestamp>" --cleanup-algorithm number
```

The hook runs only when the `snapper` binary exists, so machines without
snapper skip it silently. Number cleanup keeps the last 50 snapshots;
timeline snapshots are off, so there is no hourly noise, only pre-rebuilds
and manual ones.

## Everyday commands

```bash
sudo snapper -c root list
sudo snapper -c root create -d "before trying X"
sudo snapper -c root status 1..2
sudo snapper -c root diff 1..2 /etc/some/file
sudo snapper -c root undochange 3..5
sudo snapper -c root undochange 3..5 /etc/some/file
sudo snapper -c root delete 1
```

`list` numbers snapshots; `0` is a pseudo-entry for the current system.
`status` shows which files changed between two snapshots, `undochange`
reverts them live with no reboot. Append paths to revert selectively.

## Rescue scenarios

A switch breaks a service or a config file: find the bracketing snapshots
with `list`, inspect with `status`, revert with `undochange`. This covers
almost everything, because System Manager changes land in `/etc` and
`/run` state derived from it, all inside `@`.

A switch goes catastrophically wrong (unbootable, broken drivers): prefer
rebooting and picking the older system generation first if one exists;
snapper is the second line. A full `snapper rollback` needs attention on
this machine: fstab mounts `/` with explicit `subvol=/@`, which pins boot
to `@` regardless of the default-subvolume switch rollback performs. The
rollback itself works, but boot needs a matching fstab-side adjustment.
Do not improvise this path; work through it deliberately when it happens.

What snapshots do not cover: `/home` (by design), hardware, firmware, the
bootloader, and anything outside this disk.

## Configuration

`/etc/snapper/configs/root`, registered in `/etc/conf.d/snapper`:

```text
SUBVOLUME="/"
FSTYPE="btrfs"
QGROUP=""
SPACE_LIMIT="0.5"
FREE_LIMIT="0.2"
ALLOW_USERS=""
ALLOW_GROUPS=""
SYNC_ACL="no"
BACKGROUND_COMPARISON="yes"
NUMBER_CLEANUP="yes"
NUMBER_MIN_AGE="1800"
NUMBER_LIMIT="50"
NUMBER_LIMIT_IMPORTANT="10"
TIMELINE_CREATE="no"
TIMELINE_CLEANUP="yes"
TIMELINE_MIN_AGE="1800"
TIMELINE_LIMIT_HOURLY="10"
TIMELINE_LIMIT_DAILY="10"
TIMELINE_LIMIT_WEEKLY="0"
TIMELINE_LIMIT_MONTHLY="10"
TIMELINE_LIMIT_YEARLY="10"
EMPTY_PRE_POST_CLEANUP="yes"
EMPTY_PRE_POST_MIN_AGE="1800"
```

Quota is off (`QGROUP` empty), so there is no hard cap; `FREE_LIMIT`
makes cleanup aggressive before the disk fills. `snapper-cleanup.timer`
enforces the limits hourly. Snapshots are read-only; only rollback clones
are writable. Snapshot cost at birth is near zero (shared extents); they
grow as `/` diverges from them.

Space accounting caveat: a snapshot pins every block `/` referenced at
creation time. Deleting files (or a Nix GC run) does not free disk space
until every snapshot referencing those blocks is itself deleted or expires.
If `df` barely moves after a large cleanup, `snapper -c root list` and
suspect the oldest snapshot first.

The snapper client talks to `snapperd` over D-Bus by default. `--no-dbus`
operates directly and surfaces kernel-level errors; useful for diagnosis.

## Setup history and troubleshooting

`create-config` refuses when `/.snapshots` already exists, even as a mount
from an earlier life. The fix here was adopting the existing `@.snapshots`
subvolume with a hand-written config, not deleting it.

Errors met during setup, in order:

- `libboost_thread.so.1.92.0: cannot open shared object file`: partial
  upgrade, snapper built against newer boost-libs than installed. Fixed
  with a full `pacman -Syu`.
- `The config 'root' does not exist` with the file present: the client goes
  over D-Bus, and `snapperd` had cached the empty config list from before
  the file existed. Fixed with `systemctl restart snapperd.service`.
- `'xterm-kitty': unknown terminal type`: kitty terminfo missing system-wide.
  Fixed with `pacman -S kitty-terminfo`.
- `create snapshot failed, errno 26 (Text file busy)`: active `/swapfile`
  on `@`. Fixed by relocating swap to nested `/swap` (NOCOW, fresh file,
  fstab updated, old file removed, 32 GiB freed).
- `snapper-cleanup.service` exit 127: the hourly timer fired before snapper
  was installed. Clears on the next successful run.
