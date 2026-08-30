# make-print-ready

Rust implementation of `make-print-ready`.

Current status:

- CLI contract scaffolded (`detect`, `convert`, `split`)
- `detect` implemented natively in Rust (JSON-compatible output shape)
- `split` implemented natively in Rust with progress bar
- Catppuccin flavor selection wired (`--flavor`)
- `convert` implementation:
  - renders via `pdfium-render`
  - classifies with Catppuccin flavor-aware BG/INK split in Oklab
  - preserves uncertain edge pixels with hysteresis linking
  - applies conservative morphology for `--close`
  - quality preset tuned to avoid stroke bloat while keeping handwriting continuity
  - writes final image-based output PDF
  - optionally writes debug artifacts (rendered, confidence, seed, post-hysteresis, final, metrics)

Runtime notes:

- Requires PDFium to be loadable (`libpdfium.so`).
- In Nix, this is provided by `pdfium`; wrapper/env should expose it.
- You can also set `PDFIUM_DYNAMIC_LIB_PATH=/path/to/libpdfium.so` manually.

Current focus remaining:

- deeper threshold tuning across large handwritten corpora
- expanded integration corpus tests

Helper scripts:

- `scripts/benchmark-gate.sh`
- `scripts/quality-gate.sh`
