# youtube-tui keybinds

Custom bindings live in `modules/entertainment/youtube-tui/`; the configuration
is linked into `~/.config/youtube-tui/` by Home Manager. Other default
bindings remain available.

## Navigation and commands

| Action | Keys |
| --- | --- |
| Move up / down | `k` / `j`, `Up` / `Down` |
| Move left / right | `h` / `l`, `Left` / `Right` |
| Select | `Enter` |
| Go back / deselect | `Backspace` / `Esc` |
| Exit | `q` |
| Reload | `F5`, `r` |
| Start command capture | `:` |

## Playback and links

Global bindings work across pages:

| Action | Keys |
| --- | --- |
| Toggle mpv pause | `Space` |
| Copy current URL | `y` |
| Open current URL in browser | `f` |
| Rewind / fast-forward mpv by 5 seconds | `Left` / `Right` |

On result and video-list pages, `p` plays the selected item in mpv. `a` starts
audio-only playback; `A` starts shuffled, looping audio playback. These actions
are available in search results, popular and trending lists, playlists,
channels, watch history, feeds, and the library where an item URL is present.
