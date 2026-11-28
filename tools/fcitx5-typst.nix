{
  lib,
  libime,
  python3,
  runCommand,
  typst,
  displayName ? "Typst (Table)",
  label ? "Typst",
}:
runCommand "fcitx5-typst-${typst.version}" {
  nativeBuildInputs = [
    libime
    python3
    typst
  ];

  meta = {
    description = "Fcitx5 table input method generated from Typst's official sym module";
    license = lib.licenses.asl20;
    platforms = lib.platforms.linux;
  };
} ''
  mkdir -p "$out/share/fcitx5/table" "$out/share/fcitx5/inputmethod"

  python3 - "$out/share/fcitx5/table/typst.txt" <<'PY'
  import json
  import re
  import string
  import subprocess
  import sys
  import unicodedata

  typst_expr = """
  {
    let walk(mod, prefix) = {
      let out = (:)
      for (k, v) in dictionary(mod) {
        if prefix == "" and k == "control" { continue }
        let key = if prefix == "" { k } else { prefix + "." + k }
        if type(v) == symbol {
          out.insert(key, (default: str(v), repr: repr(v)))
        } else if type(v) == module {
          out += walk(v, key)
        }
      }
      out
    }
    walk(sym, "")
  }
  """

  raw = json.loads(
      subprocess.check_output(
          ["typst", "eval", typst_expr, "--format", "json"],
          text=True,
      )
  )

  def decode_typst_string(raw_str):
      def replace_escape(match):
          esc = match.group(1)
          if esc.startswith("u{"):
              return chr(int(esc[2:-1], 16))
          return {"\\": "\\", '"': '"', "n": "\n", "r": "\r", "t": "\t"}.get(esc, esc)
      return re.sub(r'\\(u\{[0-9a-fA-F]+\}|.)', replace_escape, raw_str)

  def has_ascii_control(value):
      return any(ord(ch) < 0x20 or ord(ch) == 0x7F for ch in value)

  def format_table_value(value):
      if any(ch in value for ch in ('"', "\\", " ", "\t")) or value.isspace():
          escaped = value.replace("\\", "\\\\").replace('"', '\\"')
          return f'"{escaped}"'
      return value

  entries = [("\\", "\\"), ("\\\\", "\\")]
  seen = set(entries)

  def add_entry(key, value):
      if has_ascii_control(value):
          return
      pair = (key, value)
      if pair not in seen:
          entries.append(pair)
          seen.add(pair)

  superscripts = {
      "0": "⁰", "1": "¹", "2": "²", "3": "³", "4": "⁴",
      "5": "⁵", "6": "⁶", "7": "⁷", "8": "⁸", "9": "⁹",
      "+": "⁺", "-": "⁻", "=": "⁼", "(": "⁽", ")": "⁾",
      "a": "ᵃ", "b": "ᵇ", "c": "ᶜ", "d": "ᵈ", "e": "ᵉ",
      "f": "ᶠ", "g": "ᵍ", "h": "ʰ", "i": "ⁱ", "j": "ʲ",
      "k": "ᵏ", "l": "ˡ", "m": "ᵐ", "n": "ⁿ", "o": "ᵒ",
      "p": "ᵖ", "r": "ʳ", "s": "ˢ", "t": "ᵗ", "u": "ᵘ",
      "v": "ᵛ", "w": "ʷ", "x": "ˣ", "y": "ʸ", "z": "ᶻ",
      "A": "ᴬ", "B": "ᴮ", "D": "ᴰ", "E": "ᴱ", "G": "ᴳ",
      "H": "ᴴ", "I": "ᴵ", "J": "ᴶ", "K": "ᴷ", "L": "ᴸ",
      "M": "ᴹ", "N": "ᴺ", "O": "ᴼ", "P": "ᴾ", "R": "ᴿ",
      "T": "ᵀ", "U": "ᵁ", "V": "ⱽ", "W": "ᵂ",
      "alpha": "ᵅ", "beta": "ᵝ", "gamma": "ᵞ", "delta": "ᵟ",
      "epsilon": "ᵋ", "theta": "ᶿ", "iota": "ᶥ", "phi": "ᶲ",
      "phi.alt": "ᵠ", "chi": "ᵡ",
  }

  subscripts = {
      "0": "₀", "1": "₁", "2": "₂", "3": "₃", "4": "₄",
      "5": "₅", "6": "₆", "7": "₇", "8": "₈", "9": "₉",
      "+": "₊", "-": "₋", "=": "₌", "(": "₍", ")": "₎",
      "a": "ₐ", "e": "ₑ", "h": "ₕ", "i": "ᵢ", "j": "ⱼ",
      "k": "ₖ", "l": "ₗ", "m": "ₘ", "n": "ₙ", "o": "ₒ",
      "p": "ₚ", "r": "ᵣ", "s": "ₛ", "t": "ₜ", "u": "ᵤ",
      "v": "ᵥ", "x": "ₓ",
      "beta": "ᵦ", "gamma": "ᵧ", "rho": "ᵨ", "phi": "ᵩ", "chi": "ᵪ",
  }

  for suffix, glyph in superscripts.items():
      add_entry(f"\\^{suffix}", glyph)

  for suffix, glyph in subscripts.items():
      add_entry(f"\\_{suffix}", glyph)

  def add_math_alphabet(prefix, upper_base=None, lower_base=None, digit_base=None, exceptions=None):
      exceptions = exceptions or {}
      if upper_base is not None:
          for offset, ch in enumerate(string.ascii_uppercase):
              glyph = exceptions.get(ch, chr(upper_base + offset))
              unicodedata.name(glyph)
              add_entry(f"\\{prefix}.{ch}", glyph)
      if lower_base is not None:
          for offset, ch in enumerate(string.ascii_lowercase):
              glyph = exceptions.get(ch, chr(lower_base + offset))
              unicodedata.name(glyph)
              add_entry(f"\\{prefix}.{ch}", glyph)
      if digit_base is not None:
          for offset, ch in enumerate(string.digits):
              glyph = exceptions.get(ch, chr(digit_base + offset))
              unicodedata.name(glyph)
              add_entry(f"\\{prefix}.{ch}", glyph)

  add_math_alphabet("bold", upper_base=0x1D400, lower_base=0x1D41A, digit_base=0x1D7CE)
  add_math_alphabet("italic", upper_base=0x1D434, lower_base=0x1D44E, exceptions={"h": "ℎ"})
  add_entry("\\italic.dotless.i", "𝚤")
  add_entry("\\italic.dotless.j", "𝚥")
  add_math_alphabet("bold.italic", upper_base=0x1D468, lower_base=0x1D482)
  add_math_alphabet(
      "cal",
      upper_base=0x1D49C,
      lower_base=0x1D4B6,
      exceptions={
          "B": "ℬ", "E": "ℰ", "F": "ℱ", "H": "ℋ",
          "I": "ℐ", "L": "ℒ", "M": "ℳ", "R": "ℛ",
          "e": "ℯ", "g": "ℊ", "o": "ℴ",
      },
  )
  add_math_alphabet("bold.cal", upper_base=0x1D4D0, lower_base=0x1D4EA)
  add_math_alphabet(
      "frak",
      upper_base=0x1D504,
      lower_base=0x1D51E,
      exceptions={"C": "ℭ", "H": "ℌ", "I": "ℑ", "R": "ℜ", "Z": "ℨ"},
  )
  add_math_alphabet("bold.frak", upper_base=0x1D56C, lower_base=0x1D586)
  add_math_alphabet(
      "bb",
      upper_base=0x1D538,
      lower_base=0x1D552,
      digit_base=0x1D7D8,
      exceptions={
          "C": "ℂ", "H": "ℍ", "N": "ℕ", "P": "ℙ",
          "Q": "ℚ", "R": "ℝ", "Z": "ℤ",
      },
  )
  add_math_alphabet("sans", upper_base=0x1D5A0, lower_base=0x1D5BA, digit_base=0x1D7E2)
  add_math_alphabet("sans.bold", upper_base=0x1D5D4, lower_base=0x1D5EE, digit_base=0x1D7EC)
  add_math_alphabet("sans.italic", upper_base=0x1D608, lower_base=0x1D622)
  add_math_alphabet("isans", upper_base=0x1D608, lower_base=0x1D622)
  add_math_alphabet("sans.bold.italic", upper_base=0x1D63C, lower_base=0x1D656)
  add_math_alphabet("mono", upper_base=0x1D670, lower_base=0x1D68A, digit_base=0x1D7F6)

  greek_upper = [
      "Alpha", "Beta", "Gamma", "Delta", "Epsilon", "Zeta", "Eta", "Theta",
      "Iota", "Kappa", "Lambda", "Mu", "Nu", "Xi", "Omicron", "Pi", "Rho",
      "Theta.alt", "Sigma", "Tau", "Upsilon", "Phi", "Chi", "Psi", "Omega",
      "nabla",
  ]
  greek_lower = [
      "alpha", "beta", "gamma", "delta", "epsilon.alt", "zeta", "eta", "theta",
      "iota", "kappa", "lambda", "mu", "nu", "xi", "omicron", "pi", "rho",
      "sigma.alt", "sigma", "tau", "upsilon", "phi.alt", "chi", "psi", "omega",
      "partial", "epsilon", "theta.alt", "kappa.alt", "phi", "rho.alt", "pi.alt",
  ]
  for prefix, upper_base, lower_base in (
      ("bold", 0x1D6A8, 0x1D6C2),
      ("italic", 0x1D6E2, 0x1D6FC),
      ("bold.italic", 0x1D71C, 0x1D736),
      ("sans.bold", 0x1D756, 0x1D770),
      ("sans.bold.italic", 0x1D790, 0x1D7AA),
  ):
      for offset, greek_name in enumerate(greek_upper):
          glyph = chr(upper_base + offset)
          unicodedata.name(glyph)
          add_entry(f"\\{prefix}.{greek_name}", glyph)
      for offset, greek_name in enumerate(greek_lower):
          glyph = chr(lower_base + offset)
          unicodedata.name(glyph)
          add_entry(f"\\{prefix}.{greek_name}", glyph)

  for name, info in sorted(raw.items()):
      add_entry(f"\\{name}", info["default"])

      repr_text = info["repr"]
      inner = repr_text[len("symbol(") : -1].strip()
      variants = []
      if inner.startswith('"'):
          bare_match = re.match(r'"((?:\\.|[^"\\])*)"', inner)
          if bare_match:
              variants.append(((), decode_typst_string(bare_match.group(1))))

      for modifier, raw_val in re.findall(
          r'\("([^"]+)",\s*"((?:\\.|[^"\\])*)"\)', repr_text
      ):
          value = decode_typst_string(raw_val)
          add_entry(f"\\{name}.{modifier}", value)
          variants.append((tuple(modifier.split(".")), value))

      if not variants or not variants[0][0]:
          continue

      # Typst allows omitting a symbol's default modifier (e.g. `arrow.double`
      # for `arrow.r.double` or `triangle.r` for `triangle.stroked.r`).
      default_mods = variants[0][0]
      default_set = set(default_mods)
      existing_mods = {".".join(mods) for mods, _ in variants if mods}

      for mods, value in variants[1:]:
          if default_set.issubset(mods):
              short_mods = tuple(m for m in mods if m not in default_set)
          elif len(default_mods) > 1 and default_mods[0] in mods:
              short_mods = tuple(m for m in mods if m != default_mods[0])
          else:
              continue

          short_str = ".".join(short_mods)
          if short_mods and short_str not in existing_mods:
              add_entry(f"\\{name}.{short_str}", value)
              existing_mods.add(short_str)

  key_codes = "".join(sorted({ch for key, _ in entries for ch in key}))
  max_length = max(len(key) for key, _ in entries)

  with open(sys.argv[1], "w", encoding="utf-8") as out_file:
      out_file.write(f"KeyCode={key_codes}\n")
      out_file.write(f"Length={max_length}\n")
      out_file.write("[Data]\n")
      for key, value in entries:
          out_file.write(f"{key} {format_table_value(value)}\n")
  PY

  libime_tabledict \
    "$out/share/fcitx5/table/typst.txt" \
    "$out/share/fcitx5/table/typst.main.dict"
  rm "$out/share/fcitx5/table/typst.txt"

  cat >"$out/share/fcitx5/inputmethod/typst.conf" <<EOF
  [InputMethod]
  Name=${displayName}
  Label=${label}
  Icon=fcitx_latex
  LangCode=*
  Addon=table
  Configurable=True

  [Table]
  File=table/typst.main.dict
  PageSize=8
  CandidateLayoutHint=Vertical
  Hint=True
  HintSeparator=
  OrderPolicy=No
  AutoSelect=False
  AutoSelectLength=0
  NoMatchAutoSelectLength=0
  Learning=False
  ExactMatch=False
  UseAlternativePageKey=True
  FirstCandidateAsPreedit=False
  PreeditCursorPositionAtBeginning=False
  CommitInvalidSegment=True
  Selection=

  [Table/PrevPage]
  0=Page_Up
  1=Left

  [Table/NextPage]
  0=Page_Down
  1=Right

  [Table/PrevCandidate]
  0=Up
  1=Control+p

  [Table/NextCandidate]
  0=Down
  1=Control+n

  [Table/DefaultCandidate]
  0=space
  1=Return
  2=KP_Enter
  EOF
''
