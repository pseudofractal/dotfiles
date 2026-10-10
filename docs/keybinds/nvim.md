# Neovim keybinds

Leader is `space`. Uppercase means `shift` plus the key (`dB` is
`space`, then `shift-b`).

## Code (`c`)

- `cr` rename symbol
- `ca` code action
- `cf` format buffer
- `cs` symbol outline (Trouble)
- `cl` LSP definitions and references (Trouble)

## Debug and diagnostics (`d`)

- `db` toggle breakpoint
- `dB` conditional breakpoint
- `dr` open debug REPL
- `dx` all diagnostics (Trouble)
- `dX` buffer diagnostics (Trouble)
- `dl` location list (Trouble)
- `dq` quickfix list (Trouble)
- `F5` continue, `F10` step over, `F11` step into, `F12` step out

## Find (`f`)

- `ff` files in project
- `fg` grep project
- `fb` grep current buffer
- `fl` resume last search
- `fa` all pickers
- `fo` recently opened files
- `fF` files from home
- `fG` files from GitHub projects
- `fh` help pages
- `fk` keymaps

## Git and goto (`g`)

- `gb` branches
- `gd` goto definition
- `gD` goto declaration
- `gr` goto references
- `gi` goto implementation
- `gy` goto type definition
- `ghs` stage hunk, `ghr` reset hunk (works on visual selections too)
- `ghS` stage buffer, `ghu` undo stage hunk, `ghR` reset buffer
- `ghp` preview hunk, `ghb` blame line, `ghd` diff this
- `]h` next hunk, `[h` previous hunk

The `gd` and `gD` pairs shadow Vim's natives, but only in buffers
with an LSP running. Everywhere else the natives still work.

## LSP (`l`)

These only exist in buffers with an LSP attached.

- `lw` and `lf` document symbols
- `lW` and `ll` workspace symbols
- `li` incoming calls, `lo` outgoing calls
- `ld` buffer diagnostics, `lD` workspace diagnostics
- `lc` run CodeLens

## Notes (`o`)

- `oe` enable markdown math, `od` disable it, `or` refresh equations
- `op` toggle Typst preview (Typst files only)

## UI (`u`)

- `uh` toggle inlay hints (LSP buffers only)
- `un` notification history, `uD` dismiss all notifications

## Windows and buffers (`w`)

- `w` save buffer
- `wh`, `wj`, `wk`, `wl` focus left, down, up, right
- `w` plus arrow keys does the same
- `ws` split below, `wv` split right
- `wo` keep only this window, `wc` close current window
- `wt` toggle terminal
- `wn` new buffer, `wp` pin buffer, `wd` close unpinned buffers
- `shift-tab` previous buffer

## Reserved and empty

- `j` is reserved for Jupyter bindings, which land later
- `L` (with `Lp` for Python) is kept for language-specific bindings

## Direct keys

- `enter` grow treesitter selection (file buffers only, falls
  through everywhere else), `backspace` shrink it
- `alt-space` grow selection in visual mode
- `-` open yazi at current file, `ctrl-up` resume last yazi session
- `ctrl-a` select all
- `n` and `N` next and previous search match
- `]]` and `[[` next and previous reference
- `?` buffer-local keymap popup

In insert mode with completions open: `tab` accepts, `up` and
`down` cycle, `ctrl-space` opens the menu, `ctrl-l` jumps the
snippet forward, `enter` does nothing to completions. `alt-l`
accepts the local AI ghost text when the model server is enabled.

Untouched Vim defaults still doing work: surround (`ys`, `ds`,
`cs`), todo-comment jumps (`]t`, `[t`).
