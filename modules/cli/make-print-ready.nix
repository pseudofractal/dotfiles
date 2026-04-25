{
  pkgs,
  lib,
  isAndroid ? false,
  ...
}: let
  py = pkgs.python3.withPackages (ps: [ps.pymupdf ps.pillow ps.numpy ps.tqdm ps.pikepdf]);
  makePrintReadyRust = pkgs.rustPlatform.buildRustPackage {
    pname = "make-print-ready";
    version = "0.1.0";
    src = ../../tools/make-print-ready-rs;
    cargoLock.lockFile = ../../tools/make-print-ready-rs/Cargo.lock;
    nativeBuildInputs = [pkgs.pkg-config pkgs.makeWrapper];
    buildInputs = [pkgs.pdfium-binaries];
    postFixup = ''
      wrapProgram "$out/bin/make-print-ready" \
        --set PDFIUM_DYNAMIC_LIB_PATH "${pkgs.pdfium-binaries}/lib/libpdfium.so"
    '';
  };
  makePrintReadyLegacy = pkgs.writeScriptBin "make-print-ready-legacy" ''
    #!${py}/bin/python
    import argparse
    import io
    import json
    import os
    import re
    import sys
    import fitz
    import pikepdf
    import numpy as np
    from PIL import Image, ImageFilter
    from tqdm import tqdm

    MOCHA = [
        "#f5e0dc","#f2cdcd","#f5c2e7","#cba6f7","#f38ba8","#eba0ac","#fab387","#f9e2af",
        "#a6e3a1","#94e2d5","#89dceb","#74c7ec","#89b4fa","#b4befe","#cdd6f4","#bac2de",
        "#a6adc8","#9399b2","#7f849c","#6c7086","#585b70","#45475a","#313244","#1e1e2e",
        "#181825","#11111b"
    ]
    BG = ["#1e1e2e","#181825","#11111b"]

    def hex_to_rgb255(hex_color):
        hex_value = hex_color.strip().lstrip("#")
        if len(hex_value) != 6 or not re.fullmatch(r"[0-9a-fA-F]{6}", hex_value):
            raise ValueError("Invalid hex color: " + hex_color)
        return (int(hex_value[0:2], 16), int(hex_value[2:4], 16), int(hex_value[4:6], 16))

    def detect_pdf(input_pdf_path):
        with pikepdf.open(input_pdf_path) as pdf:
            pages = []
            counts = {"image_xobject_pages": 0, "vector_like_pages": 0, "unknown_pages": 0}
            for i, page in enumerate(pdf.pages, start=1):
                resources = page.get("/Resources", None)
                image_xobject_count = 0
                form_xobject_count = 0
                if resources is not None and "/XObject" in resources:
                    xobjs = resources["/XObject"]
                    for name in list(xobjs.keys()):
                        xo = xobjs[name]
                        try:
                            subtype = xo.get("/Subtype", None)
                            if subtype == "/Image":
                                image_xobject_count += 1
                            elif subtype == "/Form":
                                form_xobject_count += 1
                        except Exception:
                            pass
                page_kind = "unknown"
                if image_xobject_count > 0 and form_xobject_count == 0:
                    page_kind = "image"
                elif form_xobject_count > 0 and image_xobject_count == 0:
                    page_kind = "form"
                elif image_xobject_count > 0 and form_xobject_count > 0:
                    page_kind = "mixed"
                pages.append({"page": i, "kind": page_kind, "xobject_image_count": image_xobject_count, "xobject_form_count": form_xobject_count})
                if page_kind == "image":
                    counts["image_xobject_pages"] += 1
                elif page_kind in ("form", "mixed"):
                    counts["vector_like_pages"] += 1
                else:
                    counts["unknown_pages"] += 1
            overall = "unknown"
            if len(pages) > 0 and counts["image_xobject_pages"] == len(pages):
                overall = "image"
            elif len(pages) > 0 and counts["vector_like_pages"] == len(pages):
                overall = "vector_like"
            elif counts["image_xobject_pages"] > 0 and counts["vector_like_pages"] > 0:
                overall = "mixed"
            sys.stdout.write(json.dumps({"overall": overall, "counts": counts, "pages": pages}, ensure_ascii=False, separators=(",", ":")) + "\n")

    def pil_from_pixmap(pixmap):
        mode = "RGB"
        if pixmap.n == 4:
            mode = "RGBA"
        image = Image.frombytes(mode, (pixmap.width, pixmap.height), pixmap.samples)
        if image.mode == "RGBA":
            background = Image.new("RGB", image.size, (0, 0, 0))
            background.paste(image, mask=image.split()[3])
            image = background
        return image

    def min_dist2(image_rgb_u8, colors_u8):
        image_height, image_width, _ = image_rgb_u8.shape
        image_int16 = image_rgb_u8.astype(np.int16)
        min_distances = np.full((image_height, image_width), 1 << 30, dtype=np.int32)
        for color in colors_u8:
            dr = image_int16[:, :, 0] - int(color[0])
            dg = image_int16[:, :, 1] - int(color[1])
            db = image_int16[:, :, 2] - int(color[2])
            dist2 = (dr * dr + dg * dg + db * db).astype(np.int32)
            min_distances = np.minimum(min_distances, dist2)
        return min_distances

    def catppuccin_bw_nearest(image, margin, invert, close_k):
        image_array = np.asarray(image.convert("RGB"), dtype=np.uint8)
        bg_colors = np.array([hex_to_rgb255(hex_color) for hex_color in BG], dtype=np.uint8)
        bg_set = set(BG)
        ink_colors = np.array([hex_to_rgb255(hex_color) for hex_color in MOCHA if hex_color not in bg_set], dtype=np.uint8)
        bg_dist2 = min_dist2(image_array, bg_colors)
        ink_dist2 = min_dist2(image_array, ink_colors)
        margin_value = int(margin)
        if margin_value < 0:
            margin_value = 0
        ink_mask = (ink_dist2 + margin_value) < bg_dist2
        output_pixels = np.full((image_array.shape[0], image_array.shape[1]), 255, dtype=np.uint8)
        output_pixels[ink_mask] = 0
        if invert:
            output_pixels = 255 - output_pixels
        output_image = Image.fromarray(output_pixels, mode="L")
        kernel_size = int(close_k)
        if kernel_size not in (0, 3, 5, 7, 9):
            raise SystemExit("close must be one of 0,3,5,7,9")
        if kernel_size != 0:
            output_image = output_image.filter(ImageFilter.MaxFilter(kernel_size)).filter(ImageFilter.MinFilter(kernel_size))
        return output_image

    def convert_pdf(input_pdf_path, output_pdf_path, dpi, margin, invert, close_k, quiet):
        if dpi <= 0:
            raise SystemExit("dpi must be > 0")
        source_doc = fitz.open(input_pdf_path)
        output_doc = fitz.open()
        zoom = float(dpi) / 72.0
        matrix = fitz.Matrix(zoom, zoom)
        page_numbers = range(source_doc.page_count)
        if not quiet:
            page_numbers = tqdm(page_numbers, total=source_doc.page_count, unit="page", desc="processing", dynamic_ncols=True)
        for page_number in page_numbers:
            page = source_doc.load_page(page_number)
            pixmap = page.get_pixmap(matrix=matrix, alpha=False)
            image = pil_from_pixmap(pixmap)
            bw_image = catppuccin_bw_nearest(image, margin=margin, invert=invert, close_k=close_k)
            png_buffer = io.BytesIO()
            bw_image.save(png_buffer, format="PNG", optimize=True)
            png_bytes = png_buffer.getvalue()
            page_rect = page.rect
            output_page = output_doc.new_page(width=page_rect.width, height=page_rect.height)
            output_page.insert_image(page_rect, stream=png_bytes)
        output_doc.save(output_pdf_path, deflate=True, garbage=4)
        output_doc.close()
        source_doc.close()

    def split_pdf(input_pdf_path, num_splits=None, pages_per_split=None):
        doc = fitz.open(input_pdf_path)
        total_pages = doc.page_count

        if num_splits:
            base_pages = total_pages // num_splits
            remainder = total_pages % num_splits
        else:
            base_pages = pages_per_split
            num_splits = (total_pages + base_pages - 1) // base_pages
            remainder = 0

        base_name = os.path.splitext(os.path.basename(input_pdf_path))[0]
        output_dir = base_name
        os.makedirs(output_dir, exist_ok=True)

        page_idx = 0
        for split_index in range(num_splits):
            pages_in_part = base_pages + (1 if split_index < remainder else 0)
            split_doc = fitz.open()
            for _ in range(pages_in_part):
                split_doc.insert_pdf(doc, from_page=page_idx, to_page=page_idx)
                page_idx += 1
            split_doc.save(f"{output_dir}/{split_index+1}.pdf")
            split_doc.close()

        doc.close()

    def main():
        parser = argparse.ArgumentParser(prog="make-print-ready-legacy")
        subparsers = parser.add_subparsers(dest="cmd", required=True)
        detect_parser = subparsers.add_parser("detect")
        detect_parser.add_argument("input")
        convert_parser = subparsers.add_parser("convert")
        convert_parser.add_argument("input")
        convert_parser.add_argument("output")
        convert_parser.add_argument("--dpi", type=int, default=300)
        convert_parser.add_argument("--margin", type=int, default=0)
        convert_parser.add_argument("--invert", action="store_true")
        convert_parser.add_argument("--close", type=int, default=3)
        convert_parser.add_argument("--quiet", action="store_true")
        split_parser = subparsers.add_parser("split")
        split_parser.add_argument("input")
        split_parser.add_argument("-n", "--num", type=int, default=None)
        split_parser.add_argument("-p", "--pages", type=int, default=None)
        args = parser.parse_args()
        if args.cmd == "detect":
            detect_pdf(args.input)
            return 0
        if args.cmd == "convert":
            convert_pdf(args.input, args.output, dpi=args.dpi, margin=args.margin, invert=args.invert, close_k=args.close, quiet=args.quiet)
            return 0
        if args.cmd == "split":
            if (args.num is None) == (args.pages is None):
                raise SystemExit("Specify exactly one of -n/--num or -p/--pages")
            split_pdf(args.input, num_splits=args.num, pages_per_split=args.pages)
            return 0
        return 2

    if __name__ == "__main__":
        raise SystemExit(main())
  '';
  makePrintReadyAndroidShim = pkgs.writeShellScriptBin "make-print-ready" ''
    args=()
    skip_next=0
    while [ "$#" -gt 0 ]; do
      if [ "$skip_next" -eq 1 ]; then
        skip_next=0
        shift
        continue
      fi

      case "$1" in
        --engine)
          if [ "$2" = "accurate" ]; then
            echo "make-print-ready: accurate engine is not available on Android yet; using legacy engine." >&2
          fi
          skip_next=1
          ;;
        --preset|--flavor|--debug)
          echo "make-print-ready: '$1' is ignored on Android legacy mode." >&2
          skip_next=1
          ;;
        *)
          args+=("$1")
          ;;
      esac
      shift
    done

    exec make-print-ready-legacy "''${args[@]}"
  '';
in {
  home.packages =
    [makePrintReadyLegacy]
    ++ lib.optionals (!isAndroid) [makePrintReadyRust]
    ++ lib.optionals isAndroid [makePrintReadyAndroidShim];
}
