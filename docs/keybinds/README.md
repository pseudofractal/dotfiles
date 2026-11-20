# Keybind cheatsheets

`Mod-F1` opens the keybinding browser in Vicinae. It searches keys, actions,
and application names across two sources:

- the generated Niri configuration (`~/.config/niri/config.kdl`), so every
  compositor binding is present;
- the Markdown files in this directory, which cover Neovim, kitty, yazi, aerc,
  nchat, Concord, Sioyek, youtube-tui, and Discord.

Selecting an entry copies it to the clipboard. The same list is available in a
terminal with `keybinds list`, and `keybinds open` opens the Vicinae view
directly. In Vicinae's root search, look for **Search Keybindings**.

Niri bindings are declared in `modules/desktop/niri/binds.nix`; the browser
reads them from the generated config, so add the
`hotkey-overlay-title` attribute there when a binding needs a description. For
the other applications, add a bullet or a two-column `Action | Keys` table row
to the relevant file and run `rebuild`. Backticked examples inside parentheses
stay part of a binding's description instead of becoming separate entries.
