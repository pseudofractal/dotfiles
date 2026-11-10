# Concord keybinds

Concord is the TUI Discord client. `~/.config/concord/config.toml` is owned by
Concord, while the keymap is declarative in `modules/graphical/discord.nix` and
linked to `~/.config/concord/keymap.toml`. Edit the keymap in that module and
run `rebuild` to change bindings. `concord --check-config` validates both files.

The custom keymap is arrow-first: arrow keys are primary, with Vim keys kept as
secondary fallbacks. Defaults not listed here remain in effect; see the
[upstream keymap options](https://github.com/chojs23/concord/blob/main/docs/keymap-options.md)
for every action.

## Navigation

| Action                     | Keys                                             |
| -------------------------- | ------------------------------------------------ |
| Previous / next item       | `up` / `down`, `k` / `j`                         |
| Focus previous / next      | `left` / `right`, `shift-tab` / `tab`, `h` / `l` |
| Half page up / down        | `shift-up` / `shift-down`, `ctrl-u` / `ctrl-d`   |
| Scroll viewport up / down  | `ctrl-up` / `ctrl-down`, `K` / `J`               |
| Scroll horizontally        | `shift-left` / `shift-right`, `H` / `L`          |
| Jump to top / bottom       | `home` / `end`, `gg` / `G`                       |
| Filter/search focused pane | `/`, `ctrl-f`                                    |
| Channel switcher           | `ctrl-k`, `space space`                          |

## Voice and options

| Action                       | Keys                        |
| ---------------------------- | --------------------------- |
| Mute                         | `ctrl-shift-m`, `space v m` |
| Deafen                       | `ctrl-shift-d`, `space v D` |
| Voice options (input/output) | `space v o`                 |
| Leave voice                  | `space v l`                 |
| Share screen                 | `space v s`                 |
| Options                      | `space o`, `ctrl-,`         |
| Notification inbox           | `ctrl-shift-i`, `space n`   |

`space v o` is the quickest way to switch input/output devices after connecting
Bluetooth earbuds.

## Messages

These direct message actions work from the Messages pane without opening the
action menu:

| Action                   | Keys |
| ------------------------ | ---- |
| Copy                     | `y`  |
| Reply                    | `R`  |
| Edit                     | `e`  |
| Delete (confirmation)    | `d`  |
| React                    | `r`  |
| Translate                | `T`  |
| Open URL                 | `o`  |
| Remove embeds            | `D`  |
| Play media               | `x`  |
| View attachment          | `v`  |
| Go to referenced message | `gd` |
| Show author profile      | `p`  |
| Pin/unpin                | `P`  |
| Open thread              | `t`  |
| Show reaction users      | `u`  |
| Vote in poll             | `c`  |

## Composer

| Action            | Keys                                               |
| ----------------- | -------------------------------------------------- |
| Send              | `enter`                                            |
| Newline           | `ctrl-j`, `shift-enter`, `ctrl-enter`, `alt-enter` |
| Open `$EDITOR`    | `ctrl-e`                                           |
| GIF picker        | `ctrl-g`                                           |
| Paste             | `ctrl-v`                                           |
| Translate draft   | `ctrl-t`                                           |
| Close             | `esc`                                              |
| Clear input       | `ctrl-c`                                           |
| Move by word      | `ctrl-left` / `ctrl-right`                         |
| Toggle reply ping | `alt-p`                                            |

## Contextual menus

`space a` opens the action menu for the focused pane. Server, channel, member,
thread, and notification-inbox menus keep their default single-key actions; see
the upstream keymap options for the full list.
