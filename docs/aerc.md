# aerc

aerc signs into Gmail with app passwords. They live in `secrets.yaml` under `mail.app-passwords.google`, read at runtime from the SOPS-mounted files.

## First-time setup

Make one app password per account:

- [IISER account, Google account slot 1](https://myaccount.google.com/apppasswords?authuser=1)
- [Personal account, Google account slot 0](https://myaccount.google.com/apppasswords?authuser=0)

The links follow the account order in your current Google session. If the wrong account opens, switch first or use the account chooser.

App passwords need 2-Step Verification. If the IISER account hides the option, its Workspace admin disabled app passwords and OAuth is the only way in.

Add them with `sops secrets.yaml`:

```yaml
mail:
  app-passwords:
    google:
      iiser: <IISER app password>
      personal: <personal Gmail app password>
```

Save, rebuild. aerc reads the passwords directly; no OAuth client, no oama.

Then start `aerc`.

## Keybindings

The packaged defaults stay active. `?` inside aerc lists everything for the current context.

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

The composer uses your Home Manager Neovim, so `~/.config/nvim` loads.
