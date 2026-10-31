# Watching video

mpv is the default player for local video. It remembers your position when you
quit, and exposes playback controls to desktop applications through MPRIS.
The usual mpv controls and interface are unchanged.

Run `youtube-tui` to search with RustyPipe, then highlight a result and press
`p` to play it in mpv. Its settings and keybindings are managed in
`modules/entertainment/youtube-tui/`; search state and history remain local.
The first Home Manager rebuild backs up existing conflicting settings files.

Play a supported online video with `mpv URL`. mpv uses yt-dlp to resolve
supported sites; some services, including DRM-protected streams, will not work.
If a site stops working, yt-dlp may need an update through the normal Nix input
update workflow.

For a watch party, open Syncplay, choose mpv, and agree on a server and room with
your friends. Each person needs the same video or access to the same stream.
Syncplay synchronizes playback but does not distribute video or provide voice
chat. Its shared playlist finds local files by name, so use matching filenames.
See the [Syncplay guide](https://syncplay.pl/guide/client/) for details.

In Syncplay, choose File → Set Media Directories and add `~/Movies` so its shared
playlist can find your films. Other viewers still need their own copies.

## Movies and subtitles

Keep each film in `~/Movies/Film Title (Year)/`, with its original video filename
and subtitles alongside it. The movie importer watches Downloads for filenames
containing a title, year, and release details such as `1080p` or `WEBRip`.
It waits at least five minutes after the last modification and skips files open
for writing. A small periodic retry catches downloads that were still active or
too recent when the directory changed.

Matching subtitles are placed with an existing film; ambiguous and unmatched
files stay in Downloads. Existing files are never overwritten. Paired `.sub`
and `.idx` subtitles stay in Downloads for manual handling. Downloads and
Movies must be on the same filesystem for automatic imports. The importer does
not handle nested downloads or guarantee detection of every downloader's state;
check the journal with `journalctl --user -u movie-import` if needed. Avoid
moving or deleting the hidden Syncthing files in `~/Movies`.

After the Home Manager rebuild, run `systemctl --user enable --now movie-import.path movie-import.timer` to start the watcher and retry timer.
Files moved into Movies are synchronized to Sierpinski by Syncthing.

Jamak searches OpenSubtitles with `Ctrl+u` (or `Ctrl+Shift+u` for a manual
search). It saves subtitles next to the video; if the folder is unwritable it
falls back to its mpv cache. It also downloads automatically when a video has no
subtitle track and an exact file-hash match exists. Anonymous downloads are
limited by OpenSubtitles. For a subtitle with incorrect timing, press `n` to
retime it; the original is preserved and the new file is saved beside it.

## mpv extras

- `F` and `Alt+f` select stream video and audio quality.
- `Ctrl+c` and `Ctrl+v` copy and paste media using the Wayland clipboard.
- `Ctrl+b` saves a bookmark; `b` opens bookmarks. `h` opens playback history.
- SponsorBlock marks segments by default without skipping. For solo YouTube
  playback, `mpv --profile=solo URL` enables automatic sponsor skipping. Use
  the normal player during Syncplay sessions.
- AniList tracking reads its access token from the `anilist_token` SOPS secret.
  The plugin can update AniList automatically at 85% playback, so check its
  match first: `Alt+i` opens the AniList page and `Alt+c` corrects a match.
  `Alt+a` updates progress manually; `Alt+o` opens the current folder.

Letterboxd is not connected automatically.
