#!/usr/bin/env python3
"""Apply the dotfiles-managed defaults to Inkscape's mutable preferences."""

from __future__ import annotations

import os
import shutil
import sys
import tempfile
import xml.etree.ElementTree as ET
from pathlib import Path


PALETTE_NAME = "Catppuccin Mocha Scientific"
MOCHA_BASE = "#1e1e2e"
MOCHA_TEXT = "#cdd6f4"
PEN_STYLE = (
    f"fill:none;stroke:{MOCHA_TEXT};stroke-opacity:1;stroke-linejoin:round;"
    "stroke-linecap:butt;stroke-width:0.1764mm"
)
TEXT_STYLE = (
    "line-height:1.25;font-family:'Latin Modern Sans';font-size:12pt;"
    f"fill:{MOCHA_TEXT};fill-opacity:1;stroke:none;text-orientation:auto"
)


def child_group(parent: ET.Element, group_id: str) -> ET.Element:
    for child in parent.findall("group"):
        if child.get("id") == group_id:
            return child

    return ET.SubElement(parent, "group", {"id": group_id})


def child_eventcontext(parent: ET.Element, context_id: str) -> ET.Element:
    for child in parent.findall("eventcontext"):
        if child.get("id") == context_id:
            return child

    return ET.SubElement(parent, "eventcontext", {"id": context_id})


def set_palette(parent: ET.Element, group_id: str) -> None:
    child_group(parent, group_id).set("palette", PALETTE_NAME)


def apply_preferences(preferences: Path) -> None:
    if preferences.exists():
        backup = preferences.with_name("preferences.xml.before-dotfiles-catppuccin-defaults")
        if not backup.exists():
            shutil.copy2(preferences, backup)
        parser = ET.XMLParser(target=ET.TreeBuilder(insert_comments=True))
        tree = ET.parse(preferences, parser=parser)
        root = tree.getroot()
    else:
        root = ET.Element("inkscape", {"version": "1"})
        tree = ET.ElementTree(root)

    template_base = child_group(child_group(root, "template"), "base")
    template_base.set("pagecolor", MOCHA_BASE)
    template_base.set("pageopacity", "1.0")

    tools = child_group(root, "tools")
    freehand = child_group(tools, "freehand")
    pen = child_eventcontext(freehand, "pen")
    pen.set("usecurrent", "0")
    pen.set("style", PEN_STYLE)

    text = child_eventcontext(tools, "text")
    text.set("usecurrent", "0")
    text.set("style", TEXT_STYLE)

    set_palette(child_group(root, "embedded"), "swatches")
    set_palette(child_group(root, "dialogs"), "swatches")

    ET.indent(tree, space="   ")
    preferences.parent.mkdir(parents=True, exist_ok=True)
    file_descriptor, temporary_name = tempfile.mkstemp(
        prefix=f".{preferences.name}.", dir=preferences.parent
    )
    try:
        with os.fdopen(file_descriptor, "wb") as temporary_file:
            tree.write(temporary_file, encoding="UTF-8", xml_declaration=True)
        os.chmod(temporary_name, 0o644)
        os.replace(temporary_name, preferences)
    finally:
        if os.path.exists(temporary_name):
            os.unlink(temporary_name)


if __name__ == "__main__":
    if len(sys.argv) != 2:
        raise SystemExit("usage: inkscape-defaults.py PREFERENCES_XML")

    apply_preferences(Path(sys.argv[1]))
