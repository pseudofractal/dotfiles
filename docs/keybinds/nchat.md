# Nchat keybinds

Every binding below is custom, from `key.conf`. Anything not listed
follows nchat defaults. Several destructive or noisy defaults are
deliberately disabled (`KEY_NONE`): auto compose on typing,
plain delete, delete-line-before-cursor, end-of-line jump, external
edit, and the extra help popup.

## Sending and editing

- `enter` send message
- `alt-enter` line break inside the draft
- `ctrl-c` copy, `ctrl-x` cut, `ctrl-v` paste
- `ctrl-o` save draft to file

## Messages

- `delete` delete message under cursor
- `shift-delete` delete whole chat
- `ctrl-f` forward message
- `ctrl-e` react with emoji
- `alt-m` open message in `bat`, `alt-l` open link in browser,
  `alt-o` open attachment with the system handler
- `alt-i` transfer or share file

## Chat list

- `ctrl-u` jump to next unread chat
- `alt-c` clear current view

## Compose extras

- `alt-e` emoji picker, `alt-2` mention picker
- Drafts edited externally open in neovim
  (`message_edit_command`); pasting images goes through
  `wl-paste`, notifications through `notify-send`.
