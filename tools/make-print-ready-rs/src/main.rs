use anyhow::{bail, Context, Result};
use catppuccin::{Flavor, PALETTE};
use clap::{Parser, Subcommand, ValueEnum};
use image::{DynamicImage, GrayImage, ImageFormat, Luma};
use imageproc::distance_transform::Norm;
use imageproc::filter::median_filter;
use imageproc::morphology::close;
use indicatif::{ProgressBar, ProgressStyle};
use lopdf::{Dictionary, Document, Object};
use palette::{IntoColor, Oklab, Srgb};
use pdfium_render::prelude::*;
use printpdf::{Mm, Op, PdfDocument, PdfSaveOptions, PdfWarnMsg, Pt, RawImage, XObjectTransform};
use serde::Serialize;
use std::fs;
use std::io::Cursor;
use std::path::Path;
use std::process::{Command, ExitCode};
use std::{collections::VecDeque, env};

#[derive(Debug, Clone, Copy, PartialEq, Eq, ValueEnum)]
enum FlavorArg {
  Latte,
  Frappe,
  Macchiato,
  Mocha,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq, ValueEnum)]
enum EngineArg {
  Legacy,
  Accurate,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq, ValueEnum)]
enum PresetArg {
  Quality,
  Fast,
}

#[derive(Parser)]
#[command(name = "make-print-ready")]
#[command(about = "Convert Catppuccin-themed PDFs into print-friendly black/white outputs")]
struct Cli {
  #[command(subcommand)]
  command: Commands,
}

#[derive(Subcommand)]
enum Commands {
  Detect {
    input: String,
  },
  Convert {
    /// Input PDF path
    input: String,
    /// Output PDF path
    output: String,

    /// Render DPI for conversion
    #[arg(long, default_value_t = 300)]
    dpi: u32,

    /// Bias toward background classification (non-negative; higher usually thins strokes)
    #[arg(long, default_value_t = 0)]
    margin: i32,

    /// Invert black/white output
    #[arg(long)]
    invert: bool,

    /// Morphology closing kernel (0 disables; higher smooths more but may thicken)
    #[arg(long, default_value_t = 0)]
    close: u32,

    /// Suppress progress and non-error output
    #[arg(long)]
    quiet: bool,

    /// Catppuccin flavor to classify against
    #[arg(long, value_enum, default_value_t = FlavorArg::Mocha)]
    flavor: FlavorArg,

    /// Conversion engine (legacy fallback or accurate Rust path)
    #[arg(long, value_enum, default_value_t = EngineArg::Accurate)]
    engine: EngineArg,

    /// Trade-off preset for accurate engine (quality targets cleaner, thinner handwriting)
    #[arg(long, value_enum, default_value_t = PresetArg::Quality)]
    preset: PresetArg,

    /// Write debug artifacts into this directory (accurate engine only)
    #[arg(long)]
    debug: Option<String>,
  },
  Split {
    input: String,

    #[arg(short = 'n', long)]
    num: Option<u32>,

    #[arg(short = 'p', long)]
    pages: Option<u32>,
  },
}

#[derive(Debug, Serialize)]
struct DetectCounts {
  image_xobject_pages: u32,
  vector_like_pages: u32,
  unknown_pages: u32,
}

#[derive(Debug, Serialize)]
struct DetectPage {
  page: u32,
  kind: String,
  xobject_image_count: u32,
  xobject_form_count: u32,
}

#[derive(Debug, Serialize)]
struct DetectOutput {
  overall: String,
  counts: DetectCounts,
  pages: Vec<DetectPage>,
}

fn flavor_from_arg(flavor: FlavorArg) -> &'static Flavor {
  match flavor {
    FlavorArg::Latte => &PALETTE.latte,
    FlavorArg::Frappe => &PALETTE.frappe,
    FlavorArg::Macchiato => &PALETTE.macchiato,
    FlavorArg::Mocha => &PALETTE.mocha,
  }
}

fn run_legacy_passthrough(args: &[String]) -> Result<()> {
  let legacy_depth = env::var("MPR_LEGACY_DEPTH")
    .ok()
    .and_then(|value| value.parse::<u8>().ok())
    .unwrap_or(0);
  if legacy_depth > 0 {
    bail!("legacy engine recursion detected; refusing to recurse into legacy passthrough");
  }

  let status = Command::new("make-print-ready-legacy")
    .args(args)
    .env("MPR_LEGACY_DEPTH", "1")
    .status()
    .context("failed to launch legacy make-print-ready-legacy (install fallback binary)")?;

  if status.success() {
    Ok(())
  } else {
    bail!("legacy make-print-ready exited with status: {status}");
  }
}

fn ensure_close_value(close: u32) -> Result<()> {
  if matches!(close, 0 | 3 | 5 | 7 | 9) {
    Ok(())
  } else {
    bail!("close must be one of 0,3,5,7,9");
  }
}

fn resolve_object<'a>(doc: &'a Document, object: &'a Object) -> Result<&'a Object> {
  match object {
    Object::Reference(id) => doc
      .get_object(*id)
      .context("failed to resolve object reference"),
    _ => Ok(object),
  }
}

fn resolve_dictionary<'a>(doc: &'a Document, object: &'a Object) -> Result<Option<&'a Dictionary>> {
  let resolved = resolve_object(doc, object)?;
  match resolved {
    Object::Dictionary(dict) => Ok(Some(dict)),
    Object::Stream(stream) => Ok(Some(&stream.dict)),
    _ => Ok(None),
  }
}

fn xobject_subtype(doc: &Document, object: &Object) -> Result<Option<Vec<u8>>> {
  let Some(dict) = resolve_dictionary(doc, object)? else {
    return Ok(None);
  };

  let subtype = dict.get(b"Subtype").ok();
  let Some(subtype_object) = subtype else {
    return Ok(None);
  };
  let resolved_subtype = resolve_object(doc, subtype_object)?;
  if let Object::Name(name) = resolved_subtype {
    Ok(Some(name.clone()))
  } else {
    Ok(None)
  }
}

fn run_detect_native(input: &str) -> Result<()> {
  let doc = Document::load(input).with_context(|| format!("failed to open PDF: {input}"))?;
  let pages_map = doc.get_pages();
  let mut pages = Vec::with_capacity(pages_map.len());
  let mut counts = DetectCounts {
    image_xobject_pages: 0,
    vector_like_pages: 0,
    unknown_pages: 0,
  };

  for (page_number, page_id) in pages_map {
    let page_dict = doc
      .get_dictionary(page_id)
      .with_context(|| format!("failed to read page dictionary for page {page_number}"))?;

    let mut image_xobject_count = 0_u32;
    let mut form_xobject_count = 0_u32;

    if let Ok(resources_object) = page_dict.get(b"Resources") {
      if let Some(resources_dict) = resolve_dictionary(&doc, resources_object)? {
        if let Ok(xobject_object) = resources_dict.get(b"XObject") {
          if let Some(xobject_dict) = resolve_dictionary(&doc, xobject_object)? {
            for (_, object) in xobject_dict {
              match xobject_subtype(&doc, object)? {
                Some(subtype) if subtype.as_slice() == b"Image" => image_xobject_count += 1,
                Some(subtype) if subtype.as_slice() == b"Form" => form_xobject_count += 1,
                _ => {}
              }
            }
          }
        }
      }
    }

    let page_kind = if image_xobject_count > 0 && form_xobject_count == 0 {
      "image"
    } else if form_xobject_count > 0 && image_xobject_count == 0 {
      "form"
    } else if image_xobject_count > 0 && form_xobject_count > 0 {
      "mixed"
    } else {
      "unknown"
    };

    match page_kind {
      "image" => counts.image_xobject_pages += 1,
      "form" | "mixed" => counts.vector_like_pages += 1,
      _ => counts.unknown_pages += 1,
    }

    pages.push(DetectPage {
      page: page_number,
      kind: page_kind.to_string(),
      xobject_image_count: image_xobject_count,
      xobject_form_count: form_xobject_count,
    });
  }

  let total_pages = pages.len() as u32;
  let overall = if total_pages > 0 && counts.image_xobject_pages == total_pages {
    "image"
  } else if total_pages > 0 && counts.vector_like_pages == total_pages {
    "vector_like"
  } else if counts.image_xobject_pages > 0 && counts.vector_like_pages > 0 {
    "mixed"
  } else {
    "unknown"
  };

  let output = DetectOutput {
    overall: overall.to_string(),
    counts,
    pages,
  };
  println!("{}", serde_json::to_string(&output)?);
  Ok(())
}

fn compute_split_layout(
  total_pages: u32,
  num_splits: Option<u32>,
  pages_per_split: Option<u32>,
) -> Result<Vec<u32>> {
  if total_pages == 0 {
    return Ok(Vec::new());
  }

  if let Some(parts) = num_splits {
    if parts == 0 {
      bail!("num must be > 0");
    }
    let base_pages = total_pages / parts;
    let remainder = total_pages % parts;
    let mut layout = Vec::with_capacity(parts as usize);
    for split_index in 0..parts {
      let pages_in_part = base_pages + u32::from(split_index < remainder);
      layout.push(pages_in_part);
    }
    return Ok(layout);
  }

  let pages = pages_per_split.context("pages_per_split must be provided")?;
  if pages == 0 {
    bail!("pages must be > 0");
  }
  let mut remaining = total_pages;
  let mut layout = Vec::new();
  while remaining > 0 {
    let chunk = remaining.min(pages);
    layout.push(chunk);
    remaining -= chunk;
  }
  Ok(layout)
}

fn run_split_native(
  input: &str,
  num_splits: Option<u32>,
  pages_per_split: Option<u32>,
) -> Result<()> {
  let document = Document::load(input).with_context(|| format!("failed to open PDF: {input}"))?;
  let total_pages = document.get_pages().len() as u32;
  if let Some(parts) = num_splits {
    if parts > total_pages && total_pages > 0 {
      bail!("num ({parts}) cannot exceed total pages ({total_pages})");
    }
  }
  let layout = compute_split_layout(total_pages, num_splits, pages_per_split)?;

  let input_path = Path::new(input);
  let base_name = input_path
    .file_stem()
    .and_then(|stem| stem.to_str())
    .context("failed to derive output directory from input file name")?;
  let output_dir = Path::new(base_name);
  fs::create_dir_all(output_dir).with_context(|| {
    format!(
      "failed to create output directory: {}",
      output_dir.display()
    )
  })?;

  let progress = ProgressBar::new(layout.len() as u64);
  progress.set_style(
    ProgressStyle::with_template("{spinner:.green} split {pos}/{len} [{bar:40.cyan/blue}] {msg}")?
      .progress_chars("=>-"),
  );

  let mut start_page = 1_u32;
  for (split_index, pages_in_part) in layout.iter().copied().enumerate() {
    let end_page = start_page + pages_in_part.saturating_sub(1);
    progress.set_message(format!("pages {start_page}-{end_page}"));

    let mut split_doc = document.clone();
    let mut delete_pages = Vec::new();
    for page in 1..=total_pages {
      if page < start_page || page > end_page {
        delete_pages.push(page);
      }
    }
    split_doc.delete_pages(&delete_pages);

    let output_path = output_dir.join(format!("{}.pdf", split_index + 1));
    split_doc
      .save(&output_path)
      .with_context(|| format!("failed to save split file: {}", output_path.display()))?;

    start_page = end_page + 1;
    progress.inc(1);
  }

  progress.finish_with_message("done");
  Ok(())
}

fn init_pdfium() -> Result<Pdfium> {
  let bindings = if let Ok(path) = env::var("PDFIUM_DYNAMIC_LIB_PATH") {
    Pdfium::bind_to_library(path.as_str()).map_err(|error| {
      anyhow::anyhow!(
        "failed to load PDFium from PDFIUM_DYNAMIC_LIB_PATH='{}': {}",
        path,
        error
      )
    })?
  } else {
    Pdfium::bind_to_system_library().map_err(|error| {
      anyhow::anyhow!(
        "failed to load PDFium system library (libpdfium.so): {}\nSet PDFIUM_DYNAMIC_LIB_PATH to your libpdfium.so (example: /nix/store/.../lib/libpdfium.so).",
        error
      )
    })?
  };

  Ok(Pdfium::new(bindings))
}

fn parse_hex_to_oklab(hex: &str) -> Result<Oklab> {
  let raw = hex.strip_prefix('#').unwrap_or(hex);
  if raw.len() != 6 {
    bail!("invalid hex color: {hex}");
  }
  let r =
    u8::from_str_radix(&raw[0..2], 16).with_context(|| format!("invalid hex color: {hex}"))?;
  let g =
    u8::from_str_radix(&raw[2..4], 16).with_context(|| format!("invalid hex color: {hex}"))?;
  let b =
    u8::from_str_radix(&raw[4..6], 16).with_context(|| format!("invalid hex color: {hex}"))?;
  let rgb = Srgb::new(r as f32 / 255.0, g as f32 / 255.0, b as f32 / 255.0);
  Ok(rgb.into_linear().into_color())
}

fn oklab_distance2(a: Oklab, b: Oklab) -> f32 {
  let dl = a.l - b.l;
  let da = a.a - b.a;
  let db = a.b - b.b;
  dl * dl + da * da + db * db
}

#[derive(Debug, Clone, Copy)]
struct PresetConfig {
  margin_bias_scale: f32,
  strong_threshold: f32,
  link_threshold: f32,
  hysteresis_enabled: bool,
  close_radius_cap: u8,
  edge_smoothing_passes: u8,
}

#[derive(Debug)]
struct BinarizeResult {
  final_bw: GrayImage,
  confidence_map: GrayImage,
  seed_ink_map: GrayImage,
  post_hysteresis_map: GrayImage,
}

#[derive(Debug, Serialize)]
struct PageDebugMetrics {
  page: usize,
  uncertain_pixels: u64,
  seed_ink_pixels: u64,
  final_ink_pixels: u64,
}

fn preset_config(preset: PresetArg) -> PresetConfig {
  match preset {
    PresetArg::Quality => PresetConfig {
      margin_bias_scale: 0.00045,
      strong_threshold: 0.00235,
      link_threshold: 0.00035,
      hysteresis_enabled: true,
      close_radius_cap: 4,
      edge_smoothing_passes: 1,
    },
    PresetArg::Fast => PresetConfig {
      margin_bias_scale: 0.00075,
      strong_threshold: 0.0028,
      link_threshold: 0.0002,
      hysteresis_enabled: false,
      close_radius_cap: 2,
      edge_smoothing_passes: 0,
    },
  }
}

fn apply_conservative_close(mask_bw: &GrayImage, close_k: u32, preset: PresetArg) -> GrayImage {
  if close_k == 0 {
    return mask_bw.clone();
  }

  let config = preset_config(preset);
  let requested_radius = ((close_k.saturating_sub(1)) / 2) as u8;
  let radius = requested_radius.min(config.close_radius_cap);
  if radius == 0 {
    return mask_bw.clone();
  }

  let mut foreground_white = GrayImage::new(mask_bw.width(), mask_bw.height());
  for (x, y, pixel) in mask_bw.enumerate_pixels() {
    let ink_is_black = pixel[0] == 0;
    foreground_white.put_pixel(x, y, Luma([if ink_is_black { 255 } else { 0 }]));
  }

  let mut closed_foreground = close(&foreground_white, Norm::L1, radius);
  for _ in 0..config.edge_smoothing_passes {
    closed_foreground = median_filter(&closed_foreground, 1, 1);
  }
  let mut out = GrayImage::new(mask_bw.width(), mask_bw.height());
  for (x, y, pixel) in closed_foreground.enumerate_pixels() {
    out.put_pixel(x, y, Luma([if pixel[0] > 0 { 0 } else { 255 }]));
  }
  out
}

fn convert_image_to_bw(
  rgb: &image::RgbImage,
  bg_palette: &[Oklab],
  ink_palette: &[Oklab],
  margin: i32,
  invert: bool,
  close_k: u32,
  preset: PresetArg,
) -> BinarizeResult {
  let width = rgb.width() as usize;
  let height = rgb.height() as usize;
  let config = preset_config(preset);
  let margin_bias = (margin.max(0) as f32) * config.margin_bias_scale;

  let mut scores = vec![0.0_f32; width * height];
  let mut confidence = GrayImage::new(rgb.width(), rgb.height());
  let mut seeds = GrayImage::new(rgb.width(), rgb.height());
  let mut state = vec![0_u8; width * height]; // 0 = bg, 1 = uncertain, 2 = ink

  for y in 0..height {
    for x in 0..width {
      let pixel = rgb.get_pixel(x as u32, y as u32);
      let srgb = Srgb::new(
        pixel[0] as f32 / 255.0,
        pixel[1] as f32 / 255.0,
        pixel[2] as f32 / 255.0,
      );
      let lab: Oklab = srgb.into_linear().into_color();

      let mut min_bg = f32::INFINITY;
      for bg in bg_palette {
        min_bg = min_bg.min(oklab_distance2(lab, *bg));
      }
      let mut min_ink = f32::INFINITY;
      for ink in ink_palette {
        min_ink = min_ink.min(oklab_distance2(lab, *ink));
      }

      let score = min_bg - (min_ink + margin_bias);
      let index = y * width + x;
      scores[index] = score;

      let confidence_val = ((score.abs() / config.strong_threshold).min(1.0) * 255.0) as u8;
      confidence.put_pixel(x as u32, y as u32, Luma([confidence_val]));

      if score >= config.strong_threshold {
        state[index] = 2;
        seeds.put_pixel(x as u32, y as u32, Luma([255]));
      } else if score <= -config.strong_threshold {
        state[index] = 0;
      } else {
        state[index] = 1;
      }
    }
  }

  if config.hysteresis_enabled {
    let mut queue = VecDeque::new();
    for y in 0..height {
      for x in 0..width {
        let index = y * width + x;
        if state[index] == 2 {
          queue.push_back((x, y));
        }
      }
    }

    while let Some((x, y)) = queue.pop_front() {
      let x0 = x.saturating_sub(1);
      let y0 = y.saturating_sub(1);
      let x1 = (x + 1).min(width - 1);
      let y1 = (y + 1).min(height - 1);
      for ny in y0..=y1 {
        for nx in x0..=x1 {
          if nx == x && ny == y {
            continue;
          }
          let neighbor = ny * width + nx;
          if state[neighbor] == 1 && scores[neighbor] >= config.link_threshold {
            state[neighbor] = 2;
            queue.push_back((nx, ny));
          }
        }
      }
    }
  }

  let mut post_hysteresis = GrayImage::new(rgb.width(), rgb.height());
  for y in 0..height {
    for x in 0..width {
      let index = y * width + x;
      post_hysteresis.put_pixel(
        x as u32,
        y as u32,
        Luma([if state[index] == 2 { 0 } else { 255 }]),
      );
    }
  }

  let mut final_bw = apply_conservative_close(&post_hysteresis, close_k, preset);
  if invert {
    for pixel in final_bw.pixels_mut() {
      pixel[0] = 255 - pixel[0];
    }
  }

  BinarizeResult {
    final_bw,
    confidence_map: confidence,
    seed_ink_map: seeds,
    post_hysteresis_map: post_hysteresis,
  }
}

fn points_to_mm(points: f32) -> f32 {
  points * 25.4 / 72.0
}

fn gray_image_to_png_bytes(image: &GrayImage) -> Result<Vec<u8>> {
  let mut bytes = Vec::new();
  let mut cursor = Cursor::new(&mut bytes);
  DynamicImage::ImageLuma8(image.clone())
    .write_to(&mut cursor, ImageFormat::Png)
    .context("failed to encode grayscale page as PNG")?;
  Ok(bytes)
}

fn write_bw_pages_to_pdf(
  output_path: &str,
  pages: Vec<(GrayImage, f32, f32)>,
  dpi: u32,
) -> Result<()> {
  let mut pdf = PdfDocument::new("make-print-ready-rs output");
  let mut pdf_pages = Vec::with_capacity(pages.len());
  let mut warnings = Vec::<PdfWarnMsg>::new();

  for (bw_page, width_points, height_points) in pages {
    let png_bytes = gray_image_to_png_bytes(&bw_page)?;
    let raw_image = RawImage::decode_from_bytes(&png_bytes, &mut warnings)
      .map_err(|error| anyhow::anyhow!("failed to decode page PNG for PDF embedding: {error}"))?;
    let image_id = pdf.add_image(&raw_image);
    let ops = vec![Op::UseXobject {
      id: image_id,
      transform: XObjectTransform {
        translate_x: Some(Pt(0.0)),
        translate_y: Some(Pt(0.0)),
        rotate: None,
        scale_x: None,
        scale_y: None,
        dpi: Some(dpi as f32),
      },
    }];
    pdf_pages.push(printpdf::PdfPage::new(
      Mm(points_to_mm(width_points)),
      Mm(points_to_mm(height_points)),
      ops,
    ));
  }

  pdf.with_pages(pdf_pages);
  let bytes = pdf.save(&PdfSaveOptions::default(), &mut warnings);
  fs::write(output_path, bytes)
    .with_context(|| format!("failed to write output PDF: {output_path}"))?;
  Ok(())
}

struct ConvertOptions<'a> {
  input: &'a str,
  output: &'a str,
  dpi: u32,
  margin: i32,
  invert: bool,
  close: u32,
  quiet: bool,
  flavor: &'a Flavor,
  preset: PresetArg,
  debug_dir: Option<&'a str>,
}

fn run_convert_accurate_preview(opts: ConvertOptions<'_>) -> Result<()> {
  if opts.dpi == 0 {
    bail!("dpi must be > 0");
  }

  let debug_dir = opts.debug_dir;
  if let Some(path) = debug_dir {
    fs::create_dir_all(path)
      .with_context(|| format!("failed to create debug directory: {path}"))?;
  }

  let bg_hex = [
    opts.flavor.colors.base.hex.to_string(),
    opts.flavor.colors.mantle.hex.to_string(),
    opts.flavor.colors.crust.hex.to_string(),
  ];
  let bg_palette: Vec<Oklab> = bg_hex
    .iter()
    .map(|hex| parse_hex_to_oklab(hex))
    .collect::<Result<Vec<_>>>()?;

  let mut ink_palette = Vec::new();
  for color in opts.flavor.iter() {
    let hex = color.hex.to_string();
    if !bg_hex.contains(&hex) {
      ink_palette.push(parse_hex_to_oklab(&hex)?);
    }
  }

  let pdfium = init_pdfium()?;
  let document = pdfium
    .load_pdf_from_file(opts.input, None)
    .with_context(|| format!("failed to open PDF: {}", opts.input))?;

  let page_count = document.pages().len() as u64;
  let progress = ProgressBar::new(page_count);
  if !opts.quiet {
    progress.set_style(
      ProgressStyle::with_template(
        "{spinner:.green} convert {pos}/{len} [{bar:40.cyan/blue}] {msg}",
      )?
      .progress_chars("=>-"),
    );
  } else {
    progress.set_draw_target(indicatif::ProgressDrawTarget::hidden());
  }

  let mut converted_pages: Vec<(GrayImage, f32, f32)> = Vec::with_capacity(page_count as usize);

  for (index, page) in document.pages().iter().enumerate() {
    progress.set_message(format!("rendering page {}", index + 1));
    let points_height = page.height().value;
    let points_width = page.width().value;
    let target_width = ((points_width / 72.0) * opts.dpi as f32).max(1.0) as i32;
    let render_config = PdfRenderConfig::new().set_target_width(target_width);
    let dynamic_image = page
      .render_with_config(&render_config)
      .with_context(|| format!("failed to render page {}", index + 1))?
      .as_image();
    let rgb_image = dynamic_image.into_rgb8();

    let binarized = convert_image_to_bw(
      &rgb_image,
      &bg_palette,
      &ink_palette,
      opts.margin,
      opts.invert,
      opts.close,
      opts.preset,
    );

    if let Some(path) = debug_dir {
      let rendered_path = Path::new(path).join(format!("page-{:04}-rendered.png", index + 1));
      DynamicImage::ImageRgb8(rgb_image.clone())
        .save(&rendered_path)
        .with_context(|| format!("failed to save debug image: {}", rendered_path.display()))?;

      let seed_path = Path::new(path).join(format!("page-{:04}-seed-ink.png", index + 1));
      binarized
        .seed_ink_map
        .save(&seed_path)
        .with_context(|| format!("failed to save debug image: {}", seed_path.display()))?;

      let conf_path = Path::new(path).join(format!("page-{:04}-confidence.png", index + 1));
      binarized
        .confidence_map
        .save(&conf_path)
        .with_context(|| format!("failed to save debug image: {}", conf_path.display()))?;

      let hyst_path = Path::new(path).join(format!("page-{:04}-post-hysteresis.png", index + 1));
      binarized
        .post_hysteresis_map
        .save(&hyst_path)
        .with_context(|| format!("failed to save debug image: {}", hyst_path.display()))?;

      let final_path = Path::new(path).join(format!("page-{:04}-final.png", index + 1));
      binarized
        .final_bw
        .save(&final_path)
        .with_context(|| format!("failed to save debug image: {}", final_path.display()))?;

      let seed_ink_pixels = binarized.seed_ink_map.pixels().filter(|p| p[0] > 0).count() as u64;
      let uncertain_pixels = binarized
        .confidence_map
        .pixels()
        .filter(|p| p[0] < 140)
        .count() as u64;
      let final_ink_pixels = binarized.final_bw.pixels().filter(|p| p[0] == 0).count() as u64;

      let metrics = PageDebugMetrics {
        page: index + 1,
        uncertain_pixels,
        seed_ink_pixels,
        final_ink_pixels,
      };
      let metrics_path = Path::new(path).join(format!("page-{:04}-metrics.json", index + 1));
      fs::write(&metrics_path, serde_json::to_vec_pretty(&metrics)?)
        .with_context(|| format!("failed to save debug metrics: {}", metrics_path.display()))?;
    }

    converted_pages.push((binarized.final_bw, points_width, points_height));
    progress.inc(1);
  }

  progress.finish_with_message("writing pdf");
  write_bw_pages_to_pdf(opts.output, converted_pages, opts.dpi)?;
  Ok(())
}

fn run() -> Result<()> {
  let cli = Cli::parse();

  match cli.command {
    Commands::Detect { input } => {
      run_detect_native(&input)?;
    }
    Commands::Split { input, num, pages } => {
      if num.is_some() == pages.is_some() {
        bail!("Specify exactly one of -n/--num or -p/--pages");
      }
      if num == Some(0) {
        bail!("num must be > 0");
      }
      if pages == Some(0) {
        bail!("pages must be > 0");
      }

      run_split_native(&input, num, pages)?;
    }
    Commands::Convert {
      input,
      output,
      dpi,
      margin,
      invert,
      close,
      quiet,
      flavor,
      engine,
      preset,
      debug,
    } => {
      ensure_close_value(close)?;
      let selected_flavor = flavor_from_arg(flavor);
      let background_hex = [
        selected_flavor.colors.base.hex,
        selected_flavor.colors.mantle.hex,
        selected_flavor.colors.crust.hex,
      ];

      if !quiet {
        eprintln!(
          "[make-print-ready-rs] engine={engine:?} preset={preset:?} flavor={} bg={:?}",
          selected_flavor.name, background_hex
        );
      }

      if debug.is_some() && !quiet {
        eprintln!(
          "[make-print-ready-rs] debug mode enabled; writing per-page PNGs to the debug directory"
        );
      }

      match engine {
        EngineArg::Legacy => {
          if !quiet
            && (flavor != FlavorArg::Mocha || preset != PresetArg::Quality || debug.is_some())
          {
            eprintln!(
              "[make-print-ready-rs] legacy engine ignores --flavor, --preset, and --debug"
            );
          }
          let mut args = vec![
            "convert".to_string(),
            input,
            output,
            "--dpi".to_string(),
            dpi.to_string(),
            "--margin".to_string(),
            margin.to_string(),
            "--close".to_string(),
            close.to_string(),
          ];
          if invert {
            args.push("--invert".to_string());
          }
          if quiet {
            args.push("--quiet".to_string());
          }
          run_legacy_passthrough(&args)?;
        }
        EngineArg::Accurate => {
          run_convert_accurate_preview(ConvertOptions {
            input: &input,
            output: &output,
            dpi,
            margin,
            invert,
            close,
            quiet,
            flavor: selected_flavor,
            preset,
            debug_dir: debug.as_deref(),
          })?;
        }
      }
    }
  }

  Ok(())
}

fn main() -> ExitCode {
  match run() {
    Ok(()) => ExitCode::SUCCESS,
    Err(error) => {
      eprintln!("{error}");
      ExitCode::FAILURE
    }
  }
}

#[cfg(test)]
mod tests {
  use super::*;

  #[test]
  fn split_layout_by_num_distributes_remainder_to_front() {
    let layout = compute_split_layout(10, Some(3), None).unwrap();
    assert_eq!(layout, vec![4, 3, 3]);
  }

  #[test]
  fn split_layout_by_pages_chunks_correctly() {
    let layout = compute_split_layout(10, None, Some(4)).unwrap();
    assert_eq!(layout, vec![4, 4, 2]);
  }

  #[test]
  fn split_layout_rejects_zero_pages_per_split() {
    let result = compute_split_layout(10, None, Some(0));
    assert!(result.is_err());
  }

  #[test]
  fn close_value_validation_accepts_expected_values() {
    for value in [0, 3, 5, 7, 9] {
      assert!(ensure_close_value(value).is_ok());
    }
    assert!(ensure_close_value(4).is_err());
  }
}
