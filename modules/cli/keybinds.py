"""Build and display a searchable index of every configured keybinding.

The index combines two sources:

* the generated Niri configuration, which is the authoritative list of
  compositor binds;
* the Markdown cheat sheets in ``docs/keybinds``, which document the
  bindings of the other applications.

``keybinds list`` prints one entry per line. ``keybinds open`` renders the
same entries in Vicinae's dmenu view and copies the selected entry to the
clipboard.
"""

from __future__ import annotations

import argparse
import os
import re
import shlex
import shutil
import subprocess
import sys
from dataclasses import dataclass
from pathlib import Path

DOC_APP_NAMES = {
    "aerc": "Aerc",
    "concord": "Concord",
    "discord": "Discord",
    "kitty": "Kitty",
    "nchat": "Nchat",
    "nvim": "Neovim",
    "sioyek": "Sioyek",
    "yazi": "Yazi",
    "youtube-tui": "YouTube TUI",
}

APP_ORDER = ["Niri", "Neovim"]

NIRI_KEY_NAMES = {
    "BracketLeft": "[",
    "BracketRight": "]",
    "Equal": "=",
    "Escape": "Esc",
    "Minus": "-",
    "Return": "Enter",
}

# Neovim keys that are not reached through the leader. A key in the
# "Direct keys" section is always taken literally; `gx` is the one native
# mapping documented outside that section.
NVIM_NATIVE_KEYS = {"gx"}

BULLET_RE = re.compile(r"^\s*-\s+")
KEY_RE = re.compile(r"`([^`]+)`")
SEPARATOR_ROW_RE = re.compile(r"^\s*\|(?:\s*:?-{3,}:?\s*\|)+\s*$")


@dataclass(frozen=True)
class Entry:
    app: str
    category: str
    key: str
    description: str


def clean_text(text: str) -> str:
    """Collapse whitespace and remove list punctuation around a description."""
    text = text.replace("`", "")
    text = re.sub(r"\s+", " ", text).strip()
    text = re.sub(r"^(?:and|then|or)\b[ ,]*", "", text, flags=re.IGNORECASE)
    text = re.sub(r"\(\s+", "(", text)
    text = re.sub(r"\s+\)", ")", text)
    return text.strip(" ,;:.")


def looks_like_key(key: str) -> bool:
    """Reject backticked prose such as file names or shell commands."""
    words = key.split()
    if not words or key.startswith("."):
        return False
    if len(words) > 3:
        return False
    return len(words) == 1 or words[0] == "space"


def key_groups(text: str) -> list[tuple[str, int, int]]:
    """Return (key, start, end) groups, merging sequences joined by 'then' or '/'.

    Keys inside parentheses are examples mentioned by a binding's description,
    not bindings of their own, so they stay in the description text.
    """
    groups: list[tuple[str, int, int]] = []
    previous_end: int | None = None
    for match in KEY_RE.finditer(text):
        key = match.group(1).strip()
        if not key or not looks_like_key(key):
            continue
        before = text[: match.start()]
        if before.count("(") > before.count(")"):
            continue
        if groups and previous_end is not None:
            between = text[previous_end : match.start()]
            if re.fullmatch(r"\s*then\s*", between, re.IGNORECASE):
                groups[-1] = (f"{groups[-1][0]} then {key}", groups[-1][1], match.end())
                previous_end = match.end()
                continue
            if re.fullmatch(r"\s*/\s*", between):
                groups[-1] = (f"{groups[-1][0]}/{key}", groups[-1][1], match.end())
                previous_end = match.end()
                continue
        groups.append((key, match.start(), match.end()))
        previous_end = match.end()
    return groups


def entry_descriptions(
    text: str, groups: list[tuple[str, int, int]]
) -> list[tuple[str, str]]:
    """Pair each key with the text that follows it up to the next key."""
    tail = clean_text(text[groups[-1][2] :]) if groups else ""
    result = []
    for index, (key, _start, end) in enumerate(groups):
        next_start = groups[index + 1][1] if index + 1 < len(groups) else len(text)
        description = clean_text(text[end:next_start])
        if not description or description in {"/", ",", ";", ":"}:
            description = tail
        if description:
            result.append((key, description))
    return result


def niri_description(action: str, title: str | None) -> str:
    if title:
        return title
    try:
        parts = shlex.split(action)
    except ValueError:
        return action.replace("-", " ").capitalize()
    if not parts:
        return "Unnamed binding"
    name, args = parts[0], parts[1:]
    if name == "spawn" and args:
        command = " ".join(
            Path(arg).name if arg.startswith("/nix/store/") else arg for arg in args
        )
        return f"Launch {command}"
    if name == "spawn-sh":
        return "Run shell command"
    if name == "focus-workspace" and args:
        return f"Focus workspace {args[0]}"
    return name.replace("-", " ").capitalize()


def niri_key(key: str) -> str:
    for name, symbol in NIRI_KEY_NAMES.items():
        key = re.sub(rf"\b{name}\b", symbol, key)
    return key


def parse_niri(path: Path) -> list[Entry]:
    entries: list[Entry] = []
    in_binds = False
    current_key: str | None = None
    current_title: str | None = None
    current_actions: list[str] = []

    for raw_line in path.read_text(encoding="utf-8").splitlines():
        line = raw_line.strip()
        if not in_binds:
            if re.fullmatch(r"binds\s*\{", line):
                in_binds = True
            continue

        if current_key is None:
            if line == "}":
                break
            bind = re.fullmatch(r"(\S+)\s*(.*?)\{\s*", line)
            if bind:
                title = re.search(r'hotkey-overlay-title="([^"]*)"', bind.group(2))
                current_key = niri_key(bind.group(1))
                current_title = title.group(1) if title else None
                current_actions = []
            continue

        if line == "}":
            action = current_actions[0] if current_actions else ""
            entries.append(
                Entry(
                    app="Niri",
                    category="",
                    key=current_key,
                    description=niri_description(action, current_title),
                )
            )
            current_key = None
            current_title = None
            continue

        if line:
            current_actions.append(line)

    return entries


def app_name(path: Path) -> str:
    return DOC_APP_NAMES.get(path.stem, path.stem.replace("-", " ").title())


def nvim_key(key: str, category: str) -> str:
    if category.lower() == "direct keys":
        return key
    if key in NVIM_NATIVE_KEYS:
        return key
    if key.startswith(("]", "[", "ctrl-", "alt-", "shift-")):
        return key
    if re.fullmatch(r"F\d+", key):
        return key
    if key.startswith("space "):
        return key
    return f"space {key}"


def apply_app_rules(app: str, category: str, key: str) -> str:
    if app == "Neovim":
        return nvim_key(key, category)
    return key


def parse_doc(path: Path) -> list[Entry]:
    app = app_name(path)
    category = ""
    entries: list[Entry] = []
    lines = path.read_text(encoding="utf-8").splitlines()
    index = 0
    in_fence = False

    while index < len(lines):
        line = lines[index]

        if line.strip().startswith("```"):
            in_fence = not in_fence
            index += 1
            continue
        if in_fence:
            index += 1
            continue

        if line.startswith("## "):
            category = line[3:].replace("`", "").strip()
            index += 1
            continue

        if line.strip().startswith("|"):
            rows = []
            while index < len(lines) and lines[index].strip().startswith("|"):
                rows.append(lines[index])
                index += 1
            for row_index, row in enumerate(rows):
                if SEPARATOR_ROW_RE.match(row):
                    continue
                cells = [cell.strip() for cell in row.strip().strip("|").split("|")]
                if row_index == 0 and {cell.lower() for cell in cells} <= {
                    "action",
                    "key",
                    "keys",
                }:
                    continue
                if len(cells) < 2:
                    continue
                description = clean_text(cells[0])
                keys_cell = " | ".join(cells[1:])
                groups = key_groups(keys_cell)
                if not description or not groups:
                    continue
                for key, _start, _end in groups:
                    entries.append(
                        Entry(
                            app=app,
                            category=category,
                            key=apply_app_rules(app, category, key),
                            description=description,
                        )
                    )
            continue

        if BULLET_RE.match(line):
            block = [line]
            index += 1
            while index < len(lines):
                candidate = lines[index]
                if not candidate.strip():
                    break
                if (
                    BULLET_RE.match(candidate)
                    or candidate.startswith("#")
                    or candidate.strip().startswith(("|", "```"))
                ):
                    break
                block.append(candidate)
                index += 1
            text = " ".join(part.strip() for part in block)
            text = BULLET_RE.sub("", text, count=1)
            groups = key_groups(text)
            if not groups:
                continue
            for key, description in entry_descriptions(text, groups):
                entries.append(
                    Entry(
                        app=app,
                        category=category,
                        key=apply_app_rules(app, category, key),
                        description=description,
                    )
                )
            continue

        index += 1

    return [entry for entry in entries if entry.category.lower() != "reserved"]


def collect(docs_dir: Path, niri_config: Path) -> list[Entry]:
    def app_rank(app: str) -> tuple[int, str]:
        if app in APP_ORDER:
            return (APP_ORDER.index(app), "")
        return (len(APP_ORDER), app.lower())

    entries: list[Entry] = []
    if niri_config.is_file():
        entries.extend(parse_niri(niri_config))

    skip = {"niri.md", "README.md"}
    doc_paths = [path for path in docs_dir.glob("*.md") if path.name not in skip]
    doc_paths.sort(key=lambda path: (app_rank(app_name(path)), path.name))
    for path in doc_paths:
        entries.extend(parse_doc(path))

    result: list[Entry] = []
    seen = set()
    for entry in entries:
        identity = (entry.app, entry.key)
        if identity in seen:
            continue
        seen.add(identity)
        result.append(entry)
    return result


def format_entry(entry: Entry) -> str:
    if entry.category and entry.category.lower() != entry.app.lower():
        context = f"{entry.app} / {entry.category}"
    else:
        context = entry.app
    return f"{entry.key} — {entry.description} ({context})"


def command_list(entries: list[Entry]) -> int:
    for entry in entries:
        print(format_entry(entry))
    return 0


def copy_to_clipboard(text: str) -> None:
    """Hand the entry to wl-copy without waiting for it to release the selection."""
    clipboard = shutil.which("wl-copy")
    if not clipboard:
        return
    try:
        process = subprocess.Popen(
            [clipboard],
            stdin=subprocess.PIPE,
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
            start_new_session=True,
        )
    except OSError:
        return
    if process.stdin:
        process.stdin.write(text.encode())
        process.stdin.close()


def command_open(entries: list[Entry]) -> int:
    lines = "\n".join(format_entry(entry) for entry in entries)
    try:
        result = subprocess.run(
            [
                "vicinae",
                "dmenu",
                "--navigation-title",
                "Keybindings",
                "--section-title",
                "{count} keybindings",
                "--placeholder",
                "Search keys, actions, or applications",
            ],
            input=lines,
            text=True,
            check=False,
        )
    except OSError as error:
        print(f"keybinds: could not start vicinae: {error}", file=sys.stderr)
        return 1

    selection = result.stdout.strip()
    if selection:
        copy_to_clipboard(selection)
        print(selection)
    return 0


def default_docs_dir() -> Path:
    return Path(__file__).resolve().parent.parent.parent / "docs" / "keybinds"


def default_niri_config() -> Path:
    config_home = Path(os.environ.get("XDG_CONFIG_HOME", Path.home() / ".config"))
    return config_home / "niri" / "config.kdl"


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--docs",
        type=Path,
        default=default_docs_dir(),
        help="directory containing the keybind cheat sheets",
    )
    parser.add_argument(
        "--niri-config",
        type=Path,
        default=default_niri_config(),
        help="path to the generated Niri configuration",
    )
    subparsers = parser.add_subparsers(dest="command", required=True)
    subparsers.add_parser("list", help="print every entry")
    subparsers.add_parser("open", help="open the entries in Vicinae dmenu")

    args = parser.parse_args()
    if not args.docs.is_dir():
        parser.error(f"keybind docs directory not found: {args.docs}")

    entries = collect(args.docs, args.niri_config)
    if not entries:
        parser.error("no keybindings found")
    if args.command == "open":
        return command_open(entries)
    return command_list(entries)


if __name__ == "__main__":
    sys.exit(main())
