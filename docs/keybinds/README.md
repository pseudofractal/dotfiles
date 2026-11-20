# Keybind cheatsheets

`Mod-F1` opens the **Keybindings** Vicinae extension. It starts on an
application list with icons; selecting an application shows its bindings
grouped by category. Typing in the search bar switches to results across every
application, prefixed with the application name. Selecting a binding copies
its plain key combination to the clipboard. Displayed keys use Nerd Font
modifiers and special-key glyphs from Maple Mono NF CN, and a sequence such as
`g` then `m` is shown with an arrow instead of the word "then".

The same command is available from Vicinae's root search as **Keybindings**.
In a terminal, `keybinds list` prints the index, `keybinds json` prints it as
JSON for the extension, and `keybinds open` opens the older flat dmenu view.

The index combines two sources:

- the generated Niri configuration (`~/.config/niri/config.kdl`), so every
  compositor binding is present;
- the Markdown files in this directory, which cover Neovim, kitty, yazi, aerc,
  nchat, Concord, Sioyek, youtube-tui, and Discord.

Niri bindings are declared in `modules/desktop/niri/binds.nix`; the browser
reads them from the generated config, so add the
`hotkey-overlay-title` attribute there when a binding needs a description. For
the other applications, add a bullet or a two-column `Action | Keys` table row
to the relevant file and run `rebuild`. Backticked examples inside parentheses
stay part of a binding's description instead of becoming separate entries.

The extension itself lives in `modules/cli/vicinae-keybinds`; the data comes
from the `keybinds json` command, so both stay in sync after a rebuild.
