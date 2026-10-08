# Mail

Local mail lives under `~/mails/{iiser,personal}`, synced with Gmail through
Lieer and indexed by notmuch. aerc reads the notmuch database; there is one
notmuch database for both accounts.

## Sync

Each account has a Lieer timer firing every 5 minutes:

- `lieer-iiser.service` / `lieer-personal.service` (triggered by matching
  `.timer` units).
- One run = `gmi pull` (download labels, refresh history), classify new
  mail, `gmi push` (upload tag changes). Pull runs first deliberately:
  lieer skips pushing any message changed remotely since the last pull,
  and the next pull then reverts the skipped local tags — since push
  never advances the stored historyId, the previous run's own uploads
  self-inflict that conflict and silently un-delete/un-archive mail.
  Genuine mid-run remote edits still win; retry the keybind.

First-time authorization is interactive, once per account:

```bash
lieer-auth iiser
lieer-auth personal
```

The old mbsync download under `~/Maildir` is untouched and serves as a
rollback copy.

## Classification

Deterministic notmuch rules assign per-account tags (measured at P/R ≥ 0.98
per tag on 1000+1000 mails). Priority order = list order, first match wins;
mail matching nothing stays untagged in the inbox as the triage queue —
there is deliberately no catch-all tag.

Personal (17): `security`, `bank`, `trips` (bookings, never-miss) vs `travel`
(promos), `aireads`, `learn`, `compete`, `devreads`, `news`, `jobs`,
`orders` (trackable) vs `shopping` (promos), `socials`, `invest`, `intl`,
`devtools`, `accounts`.

IISER (25): `career`, `scholarships`, `finance`, `exams`, `courses`,
`tsukuba` (exchange program, all senders), `council` (governance only),
`rooms`, `mess`, `facilities`, `wellbeing`, `notices`, `fest`, `clubs`,
`seminars`, `library`, `accounts`, `thesis` (thesis keywords, plus
supervisor mail only when directly To/Cc — broadcasts to batch lists stay
in `faculty`), `urgent`, `lostfound`, `faith`, `debate`, `peers` (student
IDs), `faculty` (named senders), `dev`.

Tags sync both ways with Gmail as labels (see `ignore_tags` in
`modules/tui/aerc.nix` to keep a tag local-only). The old `ml/*` and `ai/*`
taxonomies were removed; `ai-classified` remains ignored as a legacy marker.

Two paths classify mail:

- Each Lieer run ends with `rule-mail <account>`, tagging fresh (untagged)
  mail.
- `email-classify-backfill.service` (every 10 minutes) does the same over
  the whole archive; cheap enough to run unconditionally.

All gmi access for one account serializes on `~/mails/<account>/.gmi.lock`
(`flock -n`); on contention the run skips quietly and the next timer tick
retries, so timer-driven units never fail into a degraded session. The
backfill additionally skips runs on battery power (`ConditionACPower`) and
when less than 4 GiB of memory is available.

## Query gotchas (notmuch)

These cost real debugging time; don't "simplify" them away:

- `or` must repeat the field prefix: `(from:a or from:b)`, never
  `from:(a or b)` (silently matches nothing).
- No stemming: `subject:ticket` misses `Tickets`; use trailing wildcards
  (`ticket*`) for morphology. Whole-word matching is free: `subject:fee`
  does not match `feedback`.
- `path:` with a `/**` wildcard is silently ignored by `notmuch tag`
  (tags everything globally); use exact leaf dirs:
  `(path:acct/mail/cur or path:acct/mail/new)`. Quoted `/**` works in
  `search` (aerc folders) but keep both forms identical anyway.
- `from:` matches sender names and address parts, not just domains;
  verify short/bare terms (`from:x.com` only matches 3 mails — enumerate
  `verify@x.com`-style addresses instead). `to:` covers Cc, never Bcc.

## Resource budget

Two inference servers serve port 8013 (never at the same time), currently
unused by classification but kept for ad-hoc use:

- `email-classifier.service` (CPU, default): 5% CPU cap, lowest scheduling
  priority. Daytime mode.
- `email-classifier-gpu.service` (NVIDIA GPU): 200% CPU cap for feed
  threads. Nightly/backlog mode. The display runs on the integrated GPU,
  so the NVIDIA card is otherwise idle; still, turn everything off while
  gaming with `email-toggle off` since scheduling priority does not extend
  to the GPU.

The CPU server gets `TimeoutStopSec = 5min`: a swapped-out server needs
minutes to exit, otherwise the stop times out and the unit fails. The CUDA
build compiles once against the pinned `nixpkgs-llama` input and is never
rebuilt by routine updates.

## email-toggle

```bash
email-toggle on      # CPU classifier (5%) + fetching (default state)
email-toggle off     # stop everything (timers, running syncs, both classifiers)
email-toggle full    # GPU classifier + kick off syncs now
email-toggle         # flip between on and off
```

`full` stops the CPU service and starts the GPU one; `on` reverses that. Use
`full` overnight for the backlog, `on` again in the morning. There is
deliberately no timer for this; it is a manual switch.

## Querying

Used by aerc sidebar folders, `:search`, `:cf`, and the `notmuch` CLI.

- `tag:inbox`, `tag:unread`, `tag:flagged` — standard tags.
- `tag:ai/work` — one of the ten classifier tags listed above. Spam
  classification appears as the `ai-spam` folder.
- `path:iiser/mail/**`, `path:personal/mail/**` — restrict to one account.
- `and`, `or`, `not` with parentheses: `(a or b) and not c`.
- `from:`, `to:`, `subject:` match headers; `from:example.com` matches the
  domain.
- `date:` ranges: `date:2w..` (last two weeks),
  `date:2023-01-01..2023-06-01`, `date:..6m` (older than six months).
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

CLI (`NOTMUCH_CONFIG` is exported by default in interactive shells):

```bash
notmuch search --output=summary --limit=10 'tag:ai/work and date:1m..'
notmuch count 'tag:inbox and not tag:ai-classified'
notmuch tag +flagged -- 'subject: boarding pass* and date:1m..'
```

## Troubleshooting

- Gmail API rate limits during bulk sync are normal; Lieer backs off and the
  next timer run resumes. No progress is lost.
- A Lieer service in `failed` state after a rate error just needs its next
  timer tick (or a manual `systemctl --user start`).
- `notmuch search` needs `NOTMUCH_CONFIG`, exported by default in interactive
  shells.
- Deletes/archives that never land remotely show up in the service log as
  `update: remote has changed, will not update: <gid> (add: [...] ...)` —
  a stale-history conflict (see Sync above), not an auth or API failure.
  `gmi push -f` forces local tags through at the cost of overwriting
  concurrent remote edits; normal runs stay non-forced.
