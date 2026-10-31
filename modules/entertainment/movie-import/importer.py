#!/usr/bin/env python3
"""Move completed, recognizable movie downloads into per-film folders."""

import errno
import os
import re
import stat
import sys
import time
from pathlib import Path

QUIET_SECONDS = 300
VIDEO_EXTENSIONS = {".mkv", ".mp4", ".m4v", ".avi", ".webm", ".mov"}
SUBTITLE_EXTENSIONS = {".srt", ".ass", ".ssa", ".vtt"}
YEAR = re.compile(r"(?<!\d)(19\d{2}|20\d{2})(?!\d)")
RELEASE = re.compile(
    r"(?i)(?:\b(?:480|576|720|1080|2160|4320)p\b|\b(?:bluray|bdrip|brrip|webrip|web[ ._-]?dl|remux|hdtv|dvdrip)\b)"
)
EPISODE = re.compile(r"(?i)(?:\bS\d{1,2}[ ._-]*E\d{1,3}\b|\b\d{1,2}x\d{2}\b)")
SUBTITLE_SUFFIX = re.compile(
    r"(?i)^(?:en|eng|english|ja|jpn|japanese|es|spa|spanish|fr|fra|french|de|deu|german|multi|forced|sdh|cc|hi|19\d{2}|20\d{2}|\d{3,4}p|bluray|bdrip|brrip|webrip|web|remux)(?:\s|$)"
)


def movie_name(name: str, *, video: bool) -> str | None:
    """Return a film folder name only for recognizable release filenames."""
    stem = Path(name).stem
    if EPISODE.search(stem):
        return None
    for year in YEAR.finditer(stem):
        title = re.sub(r"[._]+", " ", stem[: year.start()]).strip(" -_()[]")
        if not title or (video and not RELEASE.search(stem[year.end() :])):
            continue
        return f"{title} ({year.group()})"
    return None


def open_for_writing(path: Path) -> bool:
    """Check accessible processes for a writable descriptor to this file."""
    target = path.stat()
    for process in Path("/proc").iterdir():
        if not process.name.isdigit():
            continue
        try:
            if process.stat().st_uid != os.getuid():
                continue
            descriptors = list((process / "fd").iterdir())
        except (OSError, PermissionError):
            continue
        for descriptor in descriptors:
            try:
                opened = descriptor.stat()
                if (opened.st_dev, opened.st_ino) != (target.st_dev, target.st_ino):
                    continue
                info = (process / "fdinfo" / descriptor.name).read_text()
                flags = int(
                    next(
                        line.split()[1]
                        for line in info.splitlines()
                        if line.startswith("flags:")
                    ),
                    8,
                )
                if flags & os.O_ACCMODE in (os.O_WRONLY, os.O_RDWR):
                    return True
            except (OSError, StopIteration, ValueError):
                continue
    return False


def subtitle_folder(name: str, movies: Path) -> Path | None:
    """Match a subtitle without a year only when its existing film is unambiguous."""
    subtitle = re.sub(r"[^\w]+", " ", Path(name).stem.casefold()).strip()
    matches = []
    for folder in movies.iterdir():
        if folder.is_symlink() or not folder.is_dir() or folder.name.startswith("."):
            continue
        title = re.sub(r"\s*\((?:19|20)\d{2}\)$", "", folder.name)
        title = re.sub(r"[^\w]+", " ", title.casefold()).strip()
        remainder = subtitle[len(title) :].strip() if subtitle.startswith(title) else ""
        if title and (
            subtitle == title
            or (subtitle.startswith(title + " ") and SUBTITLE_SUFFIX.match(remainder))
        ):
            matches.append((len(title), folder))
    if not matches:
        return None
    longest = max(length for length, _ in matches)
    best = [folder for length, folder in matches if length == longest]
    return best[0] if len(best) == 1 else None


def film_folder(folder_name: str, movies: Path) -> Path:
    """Reuse an existing yearless title folder when available."""
    exact = movies / folder_name
    if exact.exists():
        return exact
    title = re.sub(r"\s*\((?:19|20)\d{2}\)$", "", folder_name)
    existing = movies / title
    return existing if existing.is_dir() else exact


def import_downloads(
    downloads: Path, movies: Path, *, now: float | None = None
) -> bool:
    if not movies.is_dir() or not (movies / ".stfolder").is_dir():
        raise RuntimeError(f"Movies folder or Syncthing marker is missing: {movies}")
    now = time.time() if now is None else now
    succeeded = True
    candidates = sorted(
        downloads.iterdir(),
        key=lambda p: (p.suffix.lower() in SUBTITLE_EXTENSIONS, p.name),
    )
    for path in candidates:
        extension = path.suffix.lower()
        if extension not in VIDEO_EXTENSIONS | SUBTITLE_EXTENSIONS or path.is_symlink():
            continue
        try:
            before = path.stat()
            if (
                not stat.S_ISREG(before.st_mode)
                or now - before.st_mtime < QUIET_SECONDS
            ):
                continue
            folder_name = movie_name(path.name, video=extension in VIDEO_EXTENSIONS)
            if open_for_writing(path):
                continue
            if folder_name is not None:
                folder = film_folder(folder_name, movies)
                if extension in SUBTITLE_EXTENSIONS and not folder.is_dir():
                    folder = subtitle_folder(path.name, movies)
                    if folder is None:
                        continue
            elif extension in SUBTITLE_EXTENSIONS:
                folder = subtitle_folder(path.name, movies)
                if folder is None:
                    continue
            else:
                continue
            if extension in SUBTITLE_EXTENSIONS and not folder.is_dir():
                continue
            if folder.is_symlink():
                print(f"Skipping symlinked movie folder: {folder}", file=sys.stderr)
                continue
            folder.mkdir(parents=True, exist_ok=True)
            destination = folder / path.name
            after = path.stat()
            if (before.st_ino, before.st_size, before.st_mtime_ns) != (
                after.st_ino,
                after.st_size,
                after.st_mtime_ns,
            ):
                continue
            try:
                os.link(path, destination, follow_symlinks=False)
            except FileExistsError:
                print(f"Already exists; left in Downloads: {path.name}")
                continue
            except OSError as error:
                if error.errno == errno.EXDEV:
                    print(
                        f"Different filesystem; left in Downloads: {path.name}",
                        file=sys.stderr,
                    )
                    continue
                raise
            path.unlink()
            print(f"Imported {path.name} → {folder.name}")
        except FileNotFoundError:
            continue
        except OSError as error:
            print(f"Could not import {path.name}: {error}", file=sys.stderr)
            succeeded = False
    return succeeded


if __name__ == "__main__":
    sys.exit(0 if import_downloads(Path(sys.argv[1]), Path(sys.argv[2])) else 1)
