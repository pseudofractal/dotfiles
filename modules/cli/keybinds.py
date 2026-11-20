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
import json
import os
import re
import shlex
import shutil
import subprocess
import sys
from dataclasses import asdict, dataclass
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

# Nerd Font key glyphs, available in Maple Mono NF CN. The raw key stays
# unchanged for searching and copying; only the displayed form uses glyphs.
SPECIAL_KEYS = {
    "mod": "\uf31a",  # Tux: Mod is the Super/Windows key
    "super": "\uf31a",
    "meta": "\uf31a",
    "win": "\uf31a",
    "ctrl": "\U000f0634",
    "control": "\U000f0634",
    "shift": "\U000f0636",
    "alt": "\U000f0635",
    "option": "\U000f0635",
    "enter": "\U000f0311",
    "return": "\U000f0311",
    "esc": "\U000f12b7",
    "escape": "\U000f12b7",
    "tab": "\U000f0312",
    "space": "\U000f1050",
    "caps": "\U000f030e",
    "backspace": "⌫",
    "delete": "⌦",
    "insert": "Insert",
    "home": "Home",
    "end": "End",
    "pageup": "PgUp",
    "pgup": "PgUp",
    "pagedown": "PgDn",
    "pgdn": "PgDn",
    "backtab": "⇤",
    "print": "Print",
    "pause": "Pause",
    "menu": "Menu",
    "left": "\U000f06c1",
    "right": "\U000f06c2",
    "up": "\U000f06c3",
    "down": "\U000f06c0",
}

FKEY_GLYPHS = {
    1: "\U000f12ab",
    2: "\U000f12ac",
    3: "\U000f12ad",
    4: "\U000f12ae",
    5: "\U000f12af",
    6: "\U000f12b0",
    7: "\U000f12b1",
    8: "\U000f12b2",
    9: "\U000f12b3",
    10: "\U000f12b4",
    11: "\U000f12b5",
    12: "\U000f12b6",
}

# Bare keys that are names rather than prose. Multi-letter bare keys in other
# applications are usually commands mentioned in a description (for example
# `bat` in nchat's "open message in `bat`").
BARE_KEYS = {
    "backspace",
    "backtab",
    "caps",
    "delete",
    "down",
    "end",
    "enter",
    "esc",
    "escape",
    "home",
    "insert",
    "left",
    "pagedown",
    "pageup",
    "pgdn",
    "pgup",
    "print",
    "return",
    "right",
    "space",
    "tab",
    "up",
}

MODIFIER_PREFIXES = {
    "alt",
    "cmd",
    "command",
    "control",
    "ctrl",
    "meta",
    "mod",
    "option",
    "shift",
    "space",
    "super",
    "win",
}

COMBINATION_PREFIXES = MODIFIER_PREFIXES - {"space"}

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


def looks_like_key(key: str, app: str) -> bool:
    """Reject backticked prose such as file names or shell commands."""
    words = key.split()
    if not words or key.startswith("."):
        return False
    if len(words) > 3:
        return False
    if len(words) > 1 and words[0] != "space":
        return False
    if (
        key.isalpha()
        and key.islower()
        and len(key) >= 3
        and key not in BARE_KEYS
        and app != "Neovim"
    ):
        return False
    if key in {"-", "+", "=", "/", "?", ",", "."}:
        return True
    if len(key) <= 3:
        return True
    if "-" in key and "+" not in key:
        prefix = key.split()[0].split("-", 1)[0].lower()
        if prefix not in MODIFIER_PREFIXES:
            return False
    return True


def key_groups(text: str, app: str) -> list[tuple[str, int, int]]:
    """Return (key, start, end) groups, merging sequences joined by 'then' or '/'.

    Keys inside parentheses are examples mentioned by a binding's description,
    not bindings of their own, so they stay in the description text.
    """
    groups: list[tuple[str, int, int]] = []
    previous_end: int | None = None
    for match in KEY_RE.finditer(text):
        key = match.group(1).strip()
        if not key or not looks_like_key(key, app):
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
                    category="Window manager",
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
                groups = key_groups(keys_cell, app)
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
            groups = key_groups(text, app)
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

    skip_categories = {"reserved", "snippets"}
    return [entry for entry in entries if entry.category.lower() not in skip_categories]


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


def boxed_key(char: str) -> str:
    """Wrap one key in a keycap box using the combining enclosing keycap."""
    if char == "-":
        char = "−"
    return f"{char}\u20e3"


def format_char(char: str, app: str, shift_present: bool) -> str:
    """Box one key, expanding uppercase letters to Shift + lowercase.

    Niri stores bindings with capitalised key names whether or not Shift is
    pressed, so its uppercase letters are just lowercased. Everywhere else an
    uppercase letter in a cheat sheet means Shift plus the lowercase key.
    """
    if char.isalpha() and char.isupper():
        char = char.lower()
        if app != "Niri" and not shift_present:
            return f"{SPECIAL_KEYS['shift']} + {boxed_key(char)}"
    return boxed_key(char)


def format_part(part: str, app: str, shift_present: bool = False) -> str:
    lower = part.lower()
    if lower in SPECIAL_KEYS:
        return SPECIAL_KEYS[lower]
    function_key = re.fullmatch(r"[Ff](\d{1,2})", part)
    if function_key and int(function_key.group(1)) in FKEY_GLYPHS:
        return FKEY_GLYPHS[int(function_key.group(1))]
    if part.startswith("XF86") or len(part) != 1:
        return part
    return format_char(part, app, shift_present)


def format_combination(token: str, app: str) -> str:
    separator = "+" if "+" in token else "-"
    parts = [part for part in token.split(separator) if part]
    shift_present = any(part.lower() == "shift" for part in parts)
    return " + ".join(format_part(part, app, shift_present) for part in parts)


def format_token(token: str, app: str) -> str:
    if "/" in token:
        alternatives = (format_token(part, app) for part in token.split("/") if part)
        return " / ".join(alternatives)
    lower = token.lower()
    if lower in SPECIAL_KEYS:
        return SPECIAL_KEYS[lower]
    if re.fullmatch(r"[Ff]\d{1,2}", token) or token.startswith("XF86"):
        return format_part(token, app)
    first = re.split(r"[+-]", token, maxsplit=1)[0].lower()
    if first in COMBINATION_PREFIXES and re.search(r"[+-]", token):
        return format_combination(token, app)
    if len(token) == 1:
        return format_char(token, app, shift_present=False)
    return " · ".join(format_char(char, app, shift_present=False) for char in token)


def display_key(key: str, app: str) -> str:
    """Render keys as keycaps, with sequences joined by a middle dot."""
    tokens = re.split(r"\s+then\s+|\s+", key.strip())
    return " · ".join(format_token(token, app) for token in tokens if token)


def format_entry(entry: Entry) -> str:
    if entry.category and entry.category.lower() != entry.app.lower():
        context = f"{entry.app} / {entry.category}"
    else:
        context = entry.app
    return f"{display_key(entry.key, entry.app)} — {entry.description} ({context})"


def command_list(entries: list[Entry]) -> int:
    for entry in entries:
        print(format_entry(entry))
    return 0


def command_json(entries: list[Entry]) -> int:
    payload = [
        {**asdict(entry), "display": display_key(entry.key, entry.app)}
        for entry in entries
    ]
    print(json.dumps(payload, ensure_ascii=False))
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
    subparsers.add_parser("json", help="print every entry as JSON")
    subparsers.add_parser("open", help="open the entries in Vicinae dmenu")

    args = parser.parse_args()
    if not args.docs.is_dir():
        parser.error(f"keybind docs directory not found: {args.docs}")

    entries = collect(args.docs, args.niri_config)
    if not entries:
        parser.error("no keybindings found")
    if args.command == "open":
        return command_open(entries)
    if args.command == "json":
        return command_json(entries)
    return command_list(entries)


if __name__ == "__main__":
    sys.exit(main())
