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

## Languages (`L`)

Language-specific actions live under `L`, then the language, then the
action. Three or four keys is deliberate: these are used rarely, and
this keeps them out of the way of the everyday bindings.

### Web (`Lw`)

- `Lwh` expandable TypeScript hover; `ctrl-n` expands one level of
  type aliases, `ctrl-p` collapses one
- `Lwo` organize imports
- `Lwa` add the missing import for the symbol under the cursor
- `Lwe` ESLint fix all (ESLint buffers only)

### Rust (`Lr`)

- `Lra` code action, `Lre` explain the error under the cursor
- `Lrh` hover actions, `Lro` open docs for the symbol
- `Lrr` runnables, `Lrt` testables, `Lrd` debug

### Julia (`Lj`)

Reserved for Julia-the-language bindings. Notebooks live under `n`.

### Typst (`Lt`)

- `Ltp` toggle the browser preview

### Markdown (`Lm`)

- `Lme` enable math, `Lmd` disable it, `Lmr` refresh equations

## Notebook (`n`)

Notebook buffers (`.ipynb`, opened with `:JupynvimOpen`). Kernels can be
Julia or Python.

- `nr` run cell and advance (`shift-enter` also works, in insert
  mode too), `ctrl-enter` run and stay
- `nR` run all, `nA` and `nB` run above and below
- `na` and `nb` add cell above and below, `nd` delete cell
- `nk` and `nj` move cell up and down
- `nm` and `ny` convert to markdown and code
- `nK` pick kernel, `ns` and `nS` start and stop, `ni`
  interrupt, `nx` restart
- `nc` and `nC` clear cell and all outputs, `no` and `nO`
  expand and hide output, `nl` limit output lines
- `nI` save cell image, `nD` delete embedded image, `nL`
  refresh display
- `]c` and `[c` jump between cells, `]i` and `[i` between image
  cells, `ctrl-j` and `ctrl-k` drop into a cell output,
  `gx` opens the link
- `ty` attaches notebook-aware; kernel completion and hover ride
  along. Saving writes nbformat JSON.
- `nK` picks the kernel. Kernels always come from the project:
  a notebook inside a uv project auto-uses its `.venv` (just
  `uv add ipykernel`), Julia comes from a devenv shell, and
  `nK` points at either explicitly. Nothing is global. Python
  gets `ty`, Julia gets JETLS.

## LSP (`l`)

These only exist in buffers with an LSP attached.

- `lw` and `lf` document symbols
- `lW` and `ll` workspace symbols
- `li` incoming calls, `lo` outgoing calls
- `ld` buffer diagnostics, `lD` workspace diagnostics
- `lc` run CodeLens


## Test (`t`)

Neotest, currently with the Vitest adapter. Only works in projects that
have Vitest configured.

- `tt` run the test nearest the cursor, `tf` run the file, `ta` run the
  whole project
- `ts` toggle the summary panel, `to` show output for a test, `tO`
  toggle the output panel
- `td` debug the nearest test through DAP, `tS` stop the run

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

## Reserved

- `Lp` is reserved for Python tooling (the uv integration is currently
  disabled)

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
accepts the local AI ghost text when the model server is enabled. With
no completion or snippet to handle it, `tab` jumps to a pending Copilot
next-edit suggestion; press it again at the edit to apply it.
`:Sidekick nes update` requests a suggestion, `:Sidekick nes clear`
dismisses it, and `:Sidekick nes toggle` turns NES on or off.

Untouched Vim defaults still doing work: surround (`ys`, `ds`,
`cs`), todo-comment jumps (`]t`, `[t`).
