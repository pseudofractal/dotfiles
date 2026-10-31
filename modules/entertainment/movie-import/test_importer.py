import importlib.util
import os
import tempfile
import time
import unittest
from pathlib import Path
from unittest.mock import patch

spec = importlib.util.spec_from_file_location(
    "importer", Path(__file__).with_name("importer.py")
)
importer = importlib.util.module_from_spec(spec)
spec.loader.exec_module(importer)


class MovieImportTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        root = Path(self.temp.name)
        self.downloads = root / "Downloads"
        self.movies = root / "Movies"
        self.downloads.mkdir()
        self.movies.mkdir()
        (self.movies / ".stfolder").mkdir()
        self.now = time.time()

    def download(self, name, *, old=True):
        path = self.downloads / name
        path.write_bytes(b"content")
        if old:
            timestamp = self.now - importer.QUIET_SECONDS - 1
            os.utime(path, (timestamp, timestamp))
        return path

    def run_import(self):
        importer.import_downloads(self.downloads, self.movies, now=self.now)

    def test_release_formats_and_subtitles(self):
        names = [
            "Mickey 17 2025 1080p 10bit WEBRip 6CH X265 HEVC-PSA.mkv",
            "Mickey.17.2025.1080p.BluRay.DDP.5.1.10bit.H.265-iVy.mkv",
            "Mickey.17.2025.1080p.WEBRip.x265-DH.en.srt",
        ]
        for name in names:
            self.download(name)
        self.run_import()
        for name in names:
            self.assertTrue((self.movies / "Mickey 17 (2025)" / name).is_file())
            self.assertFalse((self.downloads / name).exists())

    def test_excludes_ambiguous_unfinished_and_existing(self):
        recent = self.download("Movie.2025.1080p.WEBRip.mkv", old=False)
        episode = self.download("Show.S01E01.2025.1080p.WEBRip.mkv")
        generic = self.download("recording.2025.mp4")
        unmatched = self.download("Other.Movie.2024.en.srt")
        duplicate = self.download("Film.2024.1080p.WEBRip.mkv")
        destination = self.movies / "Film (2024)" / duplicate.name
        destination.parent.mkdir()
        destination.write_bytes(b"existing")
        self.run_import()
        self.assertTrue(
            all(p.exists() for p in [recent, episode, generic, unmatched, duplicate])
        )
        self.assertEqual(destination.read_bytes(), b"existing")

    def test_open_file_and_symlink_are_not_moved(self):
        active = self.download("Active.2024.1080p.WEBRip.mkv")
        link = self.downloads / "Link.2024.1080p.WEBRip.mkv"
        link.symlink_to(active)
        with active.open("ab"):
            self.run_import()
        self.assertTrue(active.exists())
        self.assertTrue(link.is_symlink())

    def test_vobsub_pair_stays_in_downloads(self):
        (self.movies / "Film (2024)").mkdir()
        subtitle = self.download("Film.2024.en.sub")
        index = self.download("Film.2024.en.idx")
        self.run_import()
        self.assertTrue(subtitle.exists())
        self.assertTrue(index.exists())

    def test_missing_sync_marker_stops_import(self):
        (self.movies / ".stfolder").rmdir()
        source = self.download("Movie.2024.1080p.WEBRip.mkv")
        with self.assertRaises(RuntimeError):
            self.run_import()
        self.assertTrue(source.exists())

    def test_existing_yearless_folder_is_reused(self):
        existing = self.movies / "Jurassic World Rebirth"
        existing.mkdir()
        source = self.download("Jurassic.World.Rebirth.2025.1080p.WEBRip.mkv")
        self.run_import()
        self.assertTrue((existing / source.name).exists())

    def test_subtitle_without_year_needs_unique_matching_folder(self):
        (self.movies / "Jurassic World Rebirth (2025)").mkdir()
        subtitle = self.download("Jurassic World Rebirth-en.srt")
        self.run_import()
        self.assertTrue(
            (self.movies / "Jurassic World Rebirth (2025)" / subtitle.name).exists()
        )
        (self.movies / "King Kong (1933)").mkdir()
        (self.movies / "King Kong (2005)").mkdir()
        ambiguous = self.download("King Kong-en.srt")
        self.run_import()
        self.assertTrue(ambiguous.exists())

    def test_cross_filesystem_does_not_remove_original(self):
        import errno

        source = self.download("Movie.2024.1080p.WEBRip.mkv")
        with patch.object(
            importer.os,
            "link",
            side_effect=OSError(errno.EXDEV, "different filesystem"),
        ):
            self.run_import()
        self.assertTrue(source.exists())


if __name__ == "__main__":
    unittest.main()
