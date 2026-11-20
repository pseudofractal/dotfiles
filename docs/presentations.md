# Presentations

`pdfpc` is installed for presenting PDFs. It is a presenter console: one window
for the projector with only the slides, and one on the laptop with the current
and next slide, speaker notes, a timer, and an overview.

## Quick start

```fish
present slides.pdf
```

`present` runs `pdfpc -w both`, so the presenter and presentation windows stay
separate. You can also run `pdfpc` directly for its other modes.

## Why pdfpc

- Works with any PDF, including Typst and LaTeX exports.
- Notes are written in the app and stored in a `slides.pdfpc` file next to the
  PDF, so they work even when the slides contain no embedded notes.
- Shows the current and next slide, remaining time, overview, overlays, and
  videos.
- Mature, packaged in nixpkgs, and usable on Wayland.

## Speaker notes

In the presenter window, press `Ctrl+N` to edit the note for the current slide
and `Esc` to save it. Notes are Markdown by default (`-f markdown`) and stored in
the `.pdfpc` sidecar.

pdfpc also displays notes embedded in the PDF, such as Beamer notes or PDF
annotations. Notes imported from PDF annotations are read-only. For Typst
Polylux decks, `polylux2pdfpc` converts the overlay metadata to `.pdfpc`.

## Displays

List the monitors pdfpc can see:

```fish
pdfpc -M
```

Then select the presenter and presentation monitors explicitly if needed:

```fish
pdfpc -w both -1 0 -2 1 slides.pdf
```

- `-1` is the presenter monitor, `-2` the presentation monitor.
- `-w both` keeps both windows windowed; the default mode fullscreens the
  presentation window.
- `-W` enables the Wayland HiDPI workaround.

The Niri configuration pins the `pdfpc - presenter` window to `eDP-1` and
focuses it. Move the `pdfpc - presentation` window to the projector with
`Mod-P`, then fullscreen it with `Mod-Ctrl-F`.

If pdfpc still puts both windows on the laptop, add a rule for the projector
output after finding its name with `niri msg outputs`:

```nix
(rule
  [(match {app-id = "pdfpc"; title = "pdfpc - presentation";})]
  [
    {open-on-output = "HDMI-A-1";} # replace with the projector output
    {open-fullscreen = true;}
    {open-focused = false;}
  ])
```

As a last resort, run pdfpc under XWayland with `GDK_BACKEND=x11`, where it can
position its windows itself.

## Alternatives

| Tool                    | Notes                                                                                                                                                                                          |
| ----------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `pympress`              | More configurable presenter layout, media, highlighting; notes come from PDF annotations or Beamer notes, so plain PDFs need extra work. Wayland secondary-screen detection can be unreliable. |
| `beamerpresenter`       | Qt-based, rich notes, drawing and highlighting; more complex, but good if you annotate slides. Available as `beamerpresenter-poppler` or `beamerpresenter-mupdf`.                              |
| `dais`                  | Modern Rust presenter with Markdown notes, `.pdfpc` compatibility, and a browser remote. Not packaged in nixpkgs; install with Cargo if you want to try it.                                    |
| `dspdfviewer`           | Only works with Beamer's "notes on second screen" double-width PDFs.                                                                                                                           |
| `IpePresenter`          | Notes only from its own PDF annotations and has a limited PDF renderer.                                                                                                                        |
| Okular, Sioyek, Zathura | Good PDF readers, but no presenter console with notes and a separate audience window.                                                                                                          |
| LibreOffice Impress     | Has a presenter console, but only for Impress documents, not arbitrary PDFs.                                                                                                                   |
