# Aerc keybinds

Everything stock except the Gmail rebinds: since sync is tag-based,
deleting or archiving local files would just get re-downloaded.
`D` and `d` trash (`+trash -inbox`), `a` and `A` archive
(`-inbox`), `*` toggles the star (`!flagged`), `l` opens the label
prompt, and `Rd` marks read. Custom binds are marked (custom).

## Global

- `ctrl-p`, `ctrl-PgUp`, `[t` previous tab
- `ctrl-n`, `ctrl-PgDn`, `]t` next tab
- `ctrl-t` embedded terminal
- `?` keybind help
- `ctrl-c`, `ctrl-q` quit with prompt, `ctrl-z` suspend

## Message list

- `q` quit with prompt
- `j` and `down` next, `k` and `up` previous
- `ctrl-d` and `ctrl-f` jump half and full page down,
  `ctrl-u` and `ctrl-b` up; `PgDn` and `PgUp` full pages
- `g` first message, `G` last
- `J` and `ctrl-down` next folder, `K` and `ctrl-up` previous
  folder; `H` and `ctrl-left` collapse, `L` and `ctrl-right`
  expand, `tf` toggle folder
- `v` mark thread, `space` mark thread and advance, `V` mark visible
- `T` toggle threads; `zc`, `zo`, `za`, `zM`, `zR` fold controls,
  `tab` toggles the thread under cursor
- `zz`, `zt`, `zb` center, top, bottom alignment
- `enter` open message (`:recall` in Drafts)
- `D` trash (custom), `d` trash (custom)
- `a` archive (custom), `A` archive thread (custom)
- `C` and `m` compose
- `b` bounce, `c` change folder, `$` and `!` run command in
  terminal, `|` pipe
- `rr` reply all, `rq` reply all quoted, `Rr` reply, `Rq` reply quoted
- `/` search, `\` filter, `n` next result, `N` previous result,
  `esc` clear search
- `*` toggle star (custom), `l` label prompt (custom),
  `Rd` mark read (custom)
- `s` horizontal split, `S` vertical split
- `pl`, `pa`, `pd`, `pb`, `pt`, `ps` patch list, apply, drop,
  rebase, terminal, switch
- `.` repeat last command

## Message view

- `q` close, `o` and `O` open attachment or link
- `S` save, `|` pipe
- `D` trash (custom), `A` archive (custom)
- `*` toggle star (custom), `l` label prompt (custom)
- `ctrl-y` copy link, `ctrl-l` open link
- `f` forward, `rr`, `rq`, `Rr`, `Rq` same replies as the list
- `H` toggle headers; `J` and `ctrl-right` next message, `K` and
  `ctrl-left` previous; `ctrl-j` and `ctrl-down` next part,
  `ctrl-k` and `ctrl-up` previous part
- `/` toggles key passthrough, then searches; `esc` leaves
  passthrough mode

## Compose

- `ctrl-k` and `ctrl-up` previous field, `ctrl-j`, `ctrl-down`,
  and `tab` next field, `backtab` previous field
- `alt-p` and `alt-n` switch account
- `ctrl-x` gives the terminal focus

Review screen: `y` send, `n` abort, `s` sign, `x` encrypt,
`v` preview, `p` postpone, `q` choose abort or postpone,
`e` edit, `a` attach, `d` detach.
