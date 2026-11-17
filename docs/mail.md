# Mail

Local mail lives under `~/mails/{iiser,personal}`, synced with Gmail through Lieer and indexed by notmuch. aerc reads the notmuch database; one database covers both accounts.

## Sync

Each account has a Lieer timer firing every 5 minutes:

- `lieer-iiser.service` / `lieer-personal.service` (triggered by matching `.timer` units).
- One run is `gmi pull` (fetch mail and labels), then classifying new mail, then `gmi push` (upload tag changes). The pull runs first so the local repository sees remote changes before it tries to push. If Gmail reports a message changed since the locally recorded history point, Lieer can refuse that message's local update; a later pull may then replace the local tag state with Gmail's state. This can leave an archive or delete action unapplied remotely, or restore a label locally. Check the sync log and Gmail before retrying; do not use `gmi push -f` unless you are prepared to overwrite a concurrent remote label change.

First-time authorization is interactive, once per account:

```bash
lieer-auth iiser
lieer-auth personal
```

`~/mails` is the local Lieer store. There is no second local mail copy configured or
maintained by this setup. The former mbsync download at `~/Maildir` was discarded on
2026-11-15; messages that existed only there were not migrated. Gmail is the remote
source of truth: messages still present in Gmail can be synced again, while messages
deleted from Gmail are no longer available to resync.

## Classification

Deterministic notmuch rules assign per-account tags (measured at P/R ≥ 0.98 per tag on 1000+1000 mails). Priority order is list order, first match wins. Mail matching nothing stays untagged in the inbox as the triage queue. There is no catch-all tag on purpose.

Personal (17): `security`, `bank`, `trips` (bookings, never-miss) vs `travel` (promos), `aireads`, `learn`, `compete`, `devreads`, `news`, `jobs`, `orders` (trackable) vs `shopping` (promos), `socials`, `invest`, `intl`, `devtools`, `accounts`.

IISER (25): `career`, `scholarships`, `finance`, `exams`, `courses`, `tsukuba` (exchange program, all senders), `council` (governance only), `rooms`, `mess`, `facilities`, `wellbeing`, `notices`, `fest`, `clubs`, `seminars`, `library`, `accounts`, `thesis` (thesis keywords, plus supervisor mail only when directly To/Cc; broadcasts to batch lists stay in `faculty`), `urgent`, `lostfound`, `faith`, `debate`, `peers` (student IDs), `faculty` (named senders), `dev`.

Tags sync both ways with Gmail as labels (see `ignore_tags` in `modules/tui/aerc.nix` to keep a tag local-only). The old `ml/*` and `ai/*` taxonomies are gone; `ai-classified` stays ignored as a legacy marker.

Mail gets classified on two paths:

- Each Lieer run ends with `rule-mail <account>`, tagging fresh (untagged) mail.
- `email-classify-backfill.service` (every 10 minutes) does the same over the whole archive; cheap enough to run unconditionally.

All gmi access for one account goes through `~/mails/<account>/.gmi.lock` (`flock -n`). If a run finds the lock taken it skips quietly and the next timer tick retries, so timer units never fail into a degraded session. Backfill also skips on battery (`ConditionACPower`) and under 4 GiB free memory.

## Query gotchas (notmuch)

These cost real debugging time; don't "simplify" them away:

- `or` must repeat the field prefix: `(from:a or from:b)`, never `from:(a or b)` (silently matches nothing).
- No stemming: `subject:ticket` misses `Tickets`; use trailing wildcards (`ticket*`) for morphology. Whole-word matching is free: `subject:fee` does not match `feedback`.
- `path:` with a `/**` wildcard is silently ignored by `notmuch tag` (tags everything globally); use exact leaf dirs: `(path:acct/mail/cur or path:acct/mail/new)`. Quoted `/**` works in `search` (aerc folders) but keep both forms identical anyway.
- `from:` matches sender names and address parts, not just domains; verify short/bare terms (`from:x.com` only matches 3 mails, enumerate `verify@x.com`-style addresses instead). `to:` covers Cc, never Bcc.

## Resource budget

Two inference servers share port 8013 (never both at once). Classification doesn't use them right now; they're kept for ad-hoc work:

- `email-classifier.service` (CPU, default): 5% CPU cap, lowest scheduling priority. Daytime mode.
- `email-classifier-gpu.service` (NVIDIA GPU): 200% CPU cap for the feed threads. Night/backlog mode. The display hangs off the integrated GPU so the NVIDIA card idles otherwise; still, switch everything off while gaming (`email-toggle off`), scheduling priority doesn't reach the GPU.

These are llama.cpp inference servers, separate from the deterministic Notmuch query rules above. Notmuch classification searches message headers and text against the fixed rules in `modules/tui/aerc.nix` and assigns tags directly; it does not call either model server. The CPU service runs the model without GPU layers and is capped at 5% CPU. The GPU service puts model layers on the NVIDIA GPU and allows up to 200% CPU for its feed threads. Both expose the same local endpoint on port 8013, so they must not run at the same time. The module currently defines these servers, but the mail classification and backfill scripts do not use them; `email-toggle` starts/stops them alongside mail timers anyway. They are therefore available for ad-hoc inference, not part of mail classification.

The CPU server gets `TimeoutStopSec = 5min`: a swapped-out server needs minutes to die, otherwise the stop times out and the unit fails. The CUDA build compiles once against the pinned `nixpkgs-llama` input and routine updates never rebuild it.

## email-toggle

```bash
email-toggle on      # CPU inference server (5%) + fetching (default state)
email-toggle off     # stop everything (timers, running syncs, both classifiers)
email-toggle full    # GPU inference server + kick off syncs now
email-toggle         # flip between on and off
```

`full` stops the CPU service and starts the GPU one; `on` reverses that. Run `full` overnight for the backlog, `on` again in the morning. No timer behind this; it's a manual switch.

## Querying

Used by aerc sidebar folders, `:search`, `:cf`, and the `notmuch` CLI.

- `tag:inbox`, `tag:unread`, `tag:flagged`: the standard tags.
- Account-specific tags include `tag:dev`, `tag:news`, and `tag:faculty`; see the lists above.
- `path:iiser/mail/**`, `path:personal/mail/**`: one account only.
- `and`, `or`, `not` with parentheses: `(a or b) and not c`.
- `from:`, `to:`, `subject:` match headers; `from:example.com` matches the domain.
- `date:` ranges: `date:2w..` (last two weeks), `date:2023-01-01..2023-06-01`, `date:..6m` (older than six months).
- `*` wildcards: `subject:invoice*`.
- `thread:{id}` selects a whole thread; `id:` selects one message.

```text
tag:inbox and tag:unread
tag:finance and date:6m..
path:personal/mail/** and tag:trips
(from:example.com or from:example.org) and subject:invoice*
tag:security and date:1w..
tag:spam and not tag:trash
```

CLI (`NOTMUCH_CONFIG` is already exported in interactive shells):

```bash
notmuch search --output=summary --limit=10 'tag:dev and date:1m..'
notmuch count 'tag:inbox and not tag:unread'
notmuch tag +flagged -- 'subject: boarding pass* and date:1m..'
```

## Troubleshooting

- Gmail API rate limits during bulk sync are normal. Lieer backs off, and a later timer run can resume syncing. This covers rate-limited transfers only; it does not protect messages deleted from Gmail or resolve label conflicts described above.
- A Lieer service sitting in `failed` after a rate error just needs its next timer tick (or a manual `systemctl --user start`).
- `notmuch search` needs `NOTMUCH_CONFIG`, already exported in interactive shells.
- Deletes/archives that never land remotely show up in the service log as `update: remote has changed, will not update: <gid> (add: [...] ... )`. That's the stale-history conflict from Sync above, not auth or API trouble. `gmi push -f` forces local tags through at the cost of overwriting concurrent remote edits; normal runs stay non-forced.
