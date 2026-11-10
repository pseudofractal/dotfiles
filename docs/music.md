# Listening to music

YouTube Music runs in the terminal through ytm-player. The `ytm` command
searches and browses YouTube Music, plays audio through mpv, and shows synced
lyrics from LRCLIB in a sidebar. It publishes MPRIS metadata, so the Noctalia
lyrics widget and `lrc_tty` follow the same playback.

## First-time setup

ytm-player needs a YouTube Music session. Extract cookies from Zen once:

```sh
ytm setup --browser zen
```

The session is stored in `~/.config/ytm-player/auth.json` and refreshed with
the same command when it expires. Use `ytm setup --manual` if cookie extraction
cannot read the browser profile.

## Playing music

Start the TUI with `ytm`.

- `space` play or pause, `n` and `p` change track
- `g l` library, `g s` search, `g b` browse, `z` queue
- `g L` toggle the synced lyrics sidebar
- `/` filter the current list, `?` show every keybinding
- `q` quit

The TUI keeps playing when it loses focus. A second terminal can control it
with `ytm now`, `ytm pause`, `ytm next`, and the other IPC subcommands.

## Lyrics

Synced lyrics are built in. Press `g L` in ytm-player to show them beside the
queue.

Outside the TUI, the Noctalia bar shows lyrics in its center widget, and
`lrc_tty` renders them in any terminal:

```sh
lrc_tty --timestamp --lines 5
```

Both read MPRIS metadata, so any player works, not only ytm-player. playerctld
tracks the active player, which lets `lrc_tty` follow playback without a
`--player` argument. Home Manager normally starts it at login; after the first
switch, start it in the running session with
`systemctl --user start playerctld`.

## Troubleshooting

Run `ytm doctor` for a diagnostic report. When browsing or lyrics fail after an
update, refresh the session with `ytm setup --browser zen`; if the TUI itself
misbehaves, `ytm --debug` writes verbose logs to `~/.config/ytm-player/logs/`.
