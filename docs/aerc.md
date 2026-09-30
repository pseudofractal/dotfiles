# aerc

The aerc configuration uses Gmail app passwords. They are stored in `secrets.yaml`
under `mail.app-passwords.google` and read at runtime from the SOPS-mounted files.

## First-time setup

Generate one app password for each account:

- [IISER account, Google account slot 1](https://myaccount.google.com/apppasswords?authuser=1)
- [Personal account, Google account slot 0](https://myaccount.google.com/apppasswords?authuser=0)

The links use the account order in your current Google browser session. If the
wrong account opens, switch accounts first or use the account chooser.

App passwords require 2-Step Verification. If the IISER account does not show
the option, its Workspace administrator has disabled app passwords and OAuth is
the only supported route.

After generating them, add these values to the encrypted file with `sops secrets.yaml`:

```yaml
mail:
  app-passwords:
    google:
      iiser: <IISER app password>
      personal: <personal Gmail app password>
```

After saving the encrypted values, rebuild. The app passwords are read directly
by aerc; no OAuth client or oama configuration is needed.

Then start `aerc`.

## Keybindings

The packaged default keybindings remain active. Press `?` inside aerc for the
complete context-specific list.

Global bindings:

| Key                       | Action               |
| ------------------------- | -------------------- |
| `Ctrl-p` / `Ctrl-n`       | Previous / next tab  |
| `Ctrl-PgUp` / `Ctrl-PgDn` | Previous / next tab  |
| `Ctrl-t`                  | Open terminal        |
| `Ctrl-c` or `Ctrl-q`      | Quit                 |
| `Ctrl-z`                  | Suspend aerc         |
| `?`                       | Show keybinding help |

Message list:

| Key                         | Action                                 |
| --------------------------- | -------------------------------------- |
| `j` / `k` or arrows         | Next / previous message                |
| `Ctrl-d` / `Ctrl-u`         | Move half a page down / up             |
| `Ctrl-f` / `Ctrl-b`         | Move a page down / up                  |
| `g` / `G`                   | First / last message                   |
| `J` / `K`                   | Next / previous folder                 |
| `H` / `L`                   | Collapse / expand folder               |
| `c`                         | Change folder                          |
| `Enter`                     | Open message                           |
| `d` / `D`                   | Delete with confirmation / immediately |
| `a` / `A`                   | Archive / archive marked thread        |
| `Rd`                        | Mark selected/marked messages as read  |
| `v` / `Space` / `V`         | Mark / mark and advance / mark visible |
| `T`                         | Toggle threads                         |
| `Tab` or `zc` / `zo` / `za` | Toggle / fold / unfold / toggle thread |
| `zM` / `zR`                 | Fold all / unfold all                  |
| `C` or `m`                  | Compose message                        |
| `rr` / `rq`                 | Reply all / reply all with quote       |
| `Rr` / `Rq`                 | Reply / reply with quote               |
| `/` / `\\`                  | Search / filter                        |
| `n` / `N`                   | Next / previous search result          |
| `s` / `S`                   | Horizontal / vertical split            |
| `$` or `!`                  | Run a terminal command                 |
| `\|`                        | Pipe the message through a command     |

Message view:

| Key                 | Action                                  |
| ------------------- | --------------------------------------- |
| `q`                 | Close message                           |
| `o` or `O`          | Open with the global XDG system handler |
| `S`                 | Save attachment or message part         |
| `\|`                | Pipe the current part                   |
| `D`                 | Delete                                  |
| `A`                 | Archive                                 |
| `f`                 | Forward                                 |
| `H`                 | Toggle headers                          |
| `Ctrl-k` / `Ctrl-j` | Previous / next MIME part               |
| `J` / `K`           | Next / previous message                 |
| `Ctrl-y`            | Copy link                               |
| `Ctrl-l`            | Open link                               |

Compose and review:

| Key                 | Action                             |
| ------------------- | ---------------------------------- |
| `Ctrl-k` / `Ctrl-j` | Previous / next field              |
| `Tab` / `Shift-Tab` | Next / previous field              |
| `Alt-p` / `Alt-n`   | Previous / next account            |
| `Ctrl-p` / `Ctrl-n` | Previous / next tab                |
| `Ctrl-x`            | Leave the embedded editor/terminal |
| `y`                 | Send                               |
| `n`                 | Abort and discard                  |
| `p`                 | Postpone to Drafts                 |
| `q`                 | Choose discard or postpone         |
| `e`                 | Edit again                         |
| `a` / `d`           | Attach / detach                    |
| `s` / `x`           | Toggle signing / encryption        |
| `v`                 | Preview                            |

The composer is explicitly configured to use your Home Manager Neovim binary,
so it loads the configuration under `~/.config/nvim`.
