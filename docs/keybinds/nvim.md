# Neovim keybinds

Leader is `space`. Uppercase means `shift` plus the key (`dB` is
`space`, then `shift-b`).

## Code (`c`)

- `cr` rename symbol, previewed live
- `ca` code action, previewed as a diff
- `cf` format buffer
- `cs` symbol outline (Trouble)
- `cl` LSP definitions and references (Trouble)

## Debug and diagnostics (`d`)

- `db` toggle breakpoint
- `dB` conditional breakpoint
- `dr` open debug REPL
- Julia files use the nearest `Project.toml` and the repository `scripts`
  environment when present; debugger packages stay in the shared Julia app environment
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
- `fr` find and replace across the project (grug-far)

## Git and goto (`g`)

- `gb` branches
- `gl` commit log
- `gS` working tree status
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

`:JuliaEnv` opens a read-only view of the current file's Julia project, load
path, depots, and the project providing each package name. Press `q` to close it.
Julia import completion shows packages from the project stack, local modules
after leading dots, and explicit `export` or `public` names after a colon.
Select an imported member to see its declaration, docstring, and source
location when the completion source can find them.

## Papyri (`p`)

Papyri previews Markdown and Typst while Neovim keeps the text. Saved
Markdown and Typst buffers inside the project root attach automatically;
unsaved edits stream to the preview as an overlay and never touch disk.
Decoration-less mode is on by default, so the preview starts without app
chrome; `pD` brings it back.

- `po` attach the current buffer, `pt` toggle, `pc` close
- `pd` detach but leave the tab open, `pr` reveal the cursor now
- `pf` toggle cursor following, `ps` toggle Markdown scroll mirroring
- `pP` preview the current Typst file itself instead of `main.typ`
- `pT` pick a tab, `pO` pick a heading, `p/` search (selection in visual mode)
- `p+`, `p-`, `p0` zoom in, out and reset
- `pm` toggle theme, `pl` toggle the Typst live pane
- `pD` toggle decoration-less mode, `pi` show connection state
- `pF` raise Papyri, `pR` refresh, `pq` quit
- `ph` list subcommands, `pk` force takeover, `pX` start without a document

The whole interface is the dispatcher: `:Papyri {subcommand} [value]`, for
example `:Papyri zoom 125` or `:Papyri scroll.by {"dy":200}`. Unknown names
are sent as raw control methods. Run `:checkhealth papyri` when the preview
does not connect.

The plugin itself is published from Papyri's `nvim-plugin` branch, so
`:Lazy update papyri.nvim` pulls plugin changes. The app follows the `papyri`
flake input and needs a rebuild.

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
- `s` flash jump, `S` flash to a treesitter node (normal, visual and
  operator-pending)
- `gs` in visual mode stores the selection for the wrapping snippets
  (`wrapb`, `wrapi`, `wrapl` in Markdown and Typst)
- `af`/`if` around/inside a function, `ac`/`ic` a class, and the rest of
  mini.ai's text objects
- `-` open yazi at current file, `ctrl-up` resume last yazi session
- `ctrl-a` select all
- `n` and `N` next and previous search match
- `]]` and `[[` next and previous reference
- `?` buffer-local keymap popup

## Snippets

- `fig`, `tbl`, `eq` and `pkg` scaffold Typst figures, tables, labeled
  equations and package imports

In insert mode with completions open: `tab` accepts, `up` and
`down` cycle, `ctrl-space` opens the menu, `ctrl-l` jumps the
snippet forward, `enter` does nothing to completions. In insert mode, `alt-l`
accepts the local AI inline ghost text when the model server is enabled. In any
mode, it applies a visible Copilot next-edit suggestion immediately without
first moving the cursor to the suggested edit.
`:Sidekick nes update` requests a suggestion, `:Sidekick nes clear`
dismisses it, and `:Sidekick nes toggle` turns NES on or off.

Untouched Vim defaults still doing work: surround (`ys`, `ds`,
`cs`), todo-comment jumps (`]t`, `[t`).
