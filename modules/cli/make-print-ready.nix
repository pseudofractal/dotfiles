{pkgs, ...}: let
  py = pkgs.python3.withPackages (ps: [ps.pymupdf ps.pillow ps.numpy ps.tqdm ps.pikepdf]);
in {
  home.packages = [
    (pkgs.writeScriptBin "make-print-ready" ''
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

      def hex_to_rgb255(h):
          s = h.strip().lstrip("#")
          if len(s) != 6 or not re.fullmatch(r"[0-9a-fA-F]{6}", s):
              raise ValueError("Invalid hex color: " + h)
          return (int(s[0:2], 16), int(s[2:4], 16), int(s[4:6], 16))

      def detect_pdf(inp):
          with pikepdf.open(inp) as pdf:
              pages = []
              counts = {"image_xobject_pages": 0, "vector_like_pages": 0, "unknown_pages": 0}
              for i, page in enumerate(pdf.pages, start=1):
                  resources = page.get("/Resources", None)
                  ximg = 0
                  xform = 0
                  if resources is not None and "/XObject" in resources:
                      xobjs = resources["/XObject"]
                      for name in list(xobjs.keys()):
                          xo = xobjs[name]
                          try:
                              subtype = xo.get("/Subtype", None)
                              if subtype == "/Image":
                                  ximg += 1
                              elif subtype == "/Form":
                                  xform += 1
                          except Exception:
                              pass
                  kind = "unknown"
                  if ximg > 0 and xform == 0:
                      kind = "image"
                  elif xform > 0 and ximg == 0:
                      kind = "form"
                  elif ximg > 0 and xform > 0:
                      kind = "mixed"
                  pages.append({"page": i, "kind": kind, "xobject_image_count": ximg, "xobject_form_count": xform})
                  if kind == "image":
                      counts["image_xobject_pages"] += 1
                  elif kind in ("form", "mixed"):
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

      def pil_from_pixmap(pix):
          mode = "RGB"
          if pix.n == 4:
              mode = "RGBA"
          img = Image.frombytes(mode, (pix.width, pix.height), pix.samples)
          if img.mode == "RGBA":
              bg = Image.new("RGB", img.size, (0, 0, 0))
              bg.paste(img, mask=img.split()[3])
              img = bg
          return img

      def min_dist2(arr_u8, colors_u8):
          h, w, _ = arr_u8.shape
          a = arr_u8.astype(np.int16)
          best = np.full((h, w), 1 << 30, dtype=np.int32)
          for c in colors_u8:
              d0 = a[:, :, 0] - int(c[0])
              d1 = a[:, :, 1] - int(c[1])
              d2 = a[:, :, 2] - int(c[2])
              dist2 = (d0 * d0 + d1 * d1 + d2 * d2).astype(np.int32)
              best = np.minimum(best, dist2)
          return best

      def catppuccin_bw_nearest(img, margin, invert, close_k):
          arr = np.asarray(img.convert("RGB"), dtype=np.uint8)
          bg_colors = np.array([hex_to_rgb255(h) for h in BG], dtype=np.uint8)
          bg_set = set(BG)
          ink_colors = np.array([hex_to_rgb255(h) for h in MOCHA if h not in bg_set], dtype=np.uint8)
          bg_d2 = min_dist2(arr, bg_colors)
          ink_d2 = min_dist2(arr, ink_colors)
          m = int(margin)
          if m < 0:
              m = 0
          ink_mask = (ink_d2 + m) < bg_d2
          out = np.full((arr.shape[0], arr.shape[1]), 255, dtype=np.uint8)
          out[ink_mask] = 0
          if invert:
              out = 255 - out
          im = Image.fromarray(out, mode="L")
          k = int(close_k)
          if k not in (0, 3, 5, 7, 9):
              raise SystemExit("close must be one of 0,3,5,7,9")
          if k != 0:
              im = im.filter(ImageFilter.MaxFilter(k)).filter(ImageFilter.MinFilter(k))
          return im

      def convert_pdf(inp, outp, dpi, margin, invert, close_k, quiet):
          if dpi <= 0:
              raise SystemExit("dpi must be > 0")
          doc = fitz.open(inp)
          out = fitz.open()
          zoom = float(dpi) / 72.0
          mat = fitz.Matrix(zoom, zoom)
          it = range(doc.page_count)
          if not quiet:
              it = tqdm(it, total=doc.page_count, unit="page", desc="processing", dynamic_ncols=True)
          for pno in it:
              page = doc.load_page(pno)
              pix = page.get_pixmap(matrix=mat, alpha=False)
              img = pil_from_pixmap(pix)
              bw = catppuccin_bw_nearest(img, margin=margin, invert=invert, close_k=close_k)
              buf = io.BytesIO()
              bw.save(buf, format="PNG", optimize=True)
              png = buf.getvalue()
              rect = page.rect
              newp = out.new_page(width=rect.width, height=rect.height)
              newp.insert_image(rect, stream=png)
          out.save(outp, deflate=True, garbage=4)
          out.close()
          doc.close()

      def split_pdf(inp, num_splits=None, pages_per_split=None):
          doc = fitz.open(inp)
          total_pages = doc.page_count

          if num_splits:
              base_pages = total_pages // num_splits
              remainder = total_pages % num_splits
          else:
              base_pages = pages_per_split
              num_splits = (total_pages + base_pages - 1) // base_pages
              remainder = 0

          base_name = os.path.splitext(os.path.basename(inp))[0]
          out_dir = base_name
          os.makedirs(out_dir, exist_ok=True)

          page_idx = 0
          for part in range(num_splits):
              pages_in_part = base_pages + (1 if part < remainder else 0)
              out = fitz.open()
              for _ in range(pages_in_part):
                  out.insert_pdf(doc, from_page=page_idx, to_page=page_idx)
                  page_idx += 1
              out.save(f"{out_dir}/{part+1}.pdf")
              out.close()

          doc.close()

      def main():
          ap = argparse.ArgumentParser(prog="make-print-ready")
          sub = ap.add_subparsers(dest="cmd", required=True)
          d = sub.add_parser("detect")
          d.add_argument("input")
          c = sub.add_parser("convert")
          c.add_argument("input")
          c.add_argument("output")
          c.add_argument("--dpi", type=int, default=300)
          c.add_argument("--margin", type=int, default=0)
          c.add_argument("--invert", action="store_true")
          c.add_argument("--close", type=int, default=3)
          c.add_argument("--quiet", action="store_true")
          s = sub.add_parser("split")
          s.add_argument("input")
          s.add_argument("-n", "--num", type=int, default=None)
          s.add_argument("-p", "--pages", type=int, default=None)
          a = ap.parse_args()
          if a.cmd == "detect":
              detect_pdf(a.input)
              return 0
          if a.cmd == "convert":
              convert_pdf(a.input, a.output, dpi=a.dpi, margin=a.margin, invert=a.invert, close_k=a.close, quiet=a.quiet)
              return 0
          if a.cmd == "split":
              if (a.num is None) == (a.pages is None):
                  raise SystemExit("Specify exactly one of -n/--num or -p/--pages")
              split_pdf(a.input, num_splits=a.num, pages_per_split=a.pages)
              return 0
          return 2

      if __name__ == "__main__":
          raise SystemExit(main())
    '')
  ];
}
