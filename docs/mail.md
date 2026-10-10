# Mail

Local mail lives under `~/mails/{iiser,personal}`, synced with Gmail through Lieer and indexed by notmuch. aerc reads the notmuch database; one database covers both accounts.

## Sync

Each account has a Lieer timer firing every 5 minutes:

- `lieer-iiser.service` / `lieer-personal.service` (triggered by matching `.timer` units).
- One run is `gmi pull` (fetch labels, refresh history), then classifying new mail, then `gmi push` (upload tag changes). Pull goes first on purpose. Lieer refuses to push any message changed remotely since the last pull, and the next pull then reverts the skipped local tags. Since push never moves the stored historyId forward, the previous run's own uploads trip that conflict against themselves and silently un-delete and un-archive mail. Real mid-run remote edits still win; just retry the keybind.

First-time authorization is interactive, once per account:

```bash
lieer-auth iiser
lieer-auth personal
```

The old mbsync download under `~/Maildir` sits untouched as a rollback copy.

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

The CPU server gets `TimeoutStopSec = 5min`: a swapped-out server needs minutes to die, otherwise the stop times out and the unit fails. The CUDA build compiles once against the pinned `nixpkgs-llama` input and routine updates never rebuild it.

## email-toggle

```bash
email-toggle on      # CPU classifier (5%) + fetching (default state)
email-toggle off     # stop everything (timers, running syncs, both classifiers)
email-toggle full    # GPU classifier + kick off syncs now
email-toggle         # flip between on and off
```

`full` stops the CPU service and starts the GPU one; `on` reverses that. Run `full` overnight for the backlog, `on` again in the morning. No timer behind this; it's a manual switch.

## Querying

Used by aerc sidebar folders, `:search`, `:cf`, and the `notmuch` CLI.

- `tag:inbox`, `tag:unread`, `tag:flagged`: the standard tags.
- `tag:ai/work`: one of the ten classifier tags listed above. Spam classification shows up as the `ai-spam` folder.
- `path:iiser/mail/**`, `path:personal/mail/**`: one account only.
- `and`, `or`, `not` with parentheses: `(a or b) and not c`.
- `from:`, `to:`, `subject:` match headers; `from:example.com` matches the domain.
- `date:` ranges: `date:2w..` (last two weeks), `date:2023-01-01..2023-06-01`, `date:..6m` (older than six months).
- `*` wildcards: `subject:invoice*`.
- `thread:{id}` selects a whole thread; `id:` selects one message.

```text
tag:inbox and tag:unread and not tag:ai-classified
tag:ai/billing and date:6m..
path:personal/mail/** and tag:ai/travel
(from:example.com or from:example.org) and subject:invoice*
tag:ai/security and date:1w..
tag:ai/spam and not tag:trash
```

CLI (`NOTMUCH_CONFIG` is already exported in interactive shells):

```bash
notmuch search --output=summary --limit=10 'tag:ai/work and date:1m..'
notmuch count 'tag:inbox and not tag:ai-classified'
notmuch tag +flagged -- 'subject: boarding pass* and date:1m..'
```

## Troubleshooting

- Gmail API rate limits during bulk sync are normal. Lieer backs off and the next timer run resumes; nothing is lost.
- A Lieer service sitting in `failed` after a rate error just needs its next timer tick (or a manual `systemctl --user start`).
- `notmuch search` needs `NOTMUCH_CONFIG`, already exported in interactive shells.
- Deletes/archives that never land remotely show up in the service log as `update: remote has changed, will not update: <gid> (add: [...] ... )`. That's the stale-history conflict from Sync above, not auth or API trouble. `gmi push -f` forces local tags through at the cost of overwriting concurrent remote edits; normal runs stay non-forced.
