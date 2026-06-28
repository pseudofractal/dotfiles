use std::borrow::Cow;
use std::collections::VecDeque;
use std::env;
use std::fs;

use anyhow::{Context, Result, bail};
use catppuccin::{Flavor, PALETTE};
use fast_srgb8::srgb8_to_f32;
use image::GrayImage;
use imageproc::distance_transform::Norm;
use imageproc::filter::median_filter;
use imageproc::morphology::close;
use indicatif::{ProgressBar, ProgressStyle};
use lopdf::{Dictionary, Document, Object};
use palette::{IntoColor, Oklab, Srgb};
use pdfium_render::prelude::*;
use printpdf::{
  Mm, Op, PdfDocument, PdfSaveOptions, PdfWarnMsg, Pt, RawImage, RawImageData, RawImageFormat,
  XObjectTransform,
};
use rayon::prelude::*;
use serde::Serialize;
use std::path::Path;

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum PresetArg {
  Quality,
  Fast,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum FlavorArg {
  Latte,
  Frappe,
  Macchiato,
  Mocha,
}

pub fn flavor_from_arg(flavor: FlavorArg) -> &'static Flavor {
  match flavor {
    FlavorArg::Latte => &PALETTE.latte,
    FlavorArg::Frappe => &PALETTE.frappe,
    FlavorArg::Macchiato => &PALETTE.macchiato,
    FlavorArg::Mocha => &PALETTE.mocha,
  }
}

pub fn ensure_close_value(_close: u32) -> Result<()> {
  Ok(())
}

pub fn compute_render_target_width(points_width: f32, dpi: u32) -> Result<i32> {
  let raw = (points_width / 72.0) * dpi as f32;
  let clamped = raw.max(1.0);
  if clamped > i32::MAX as f32 {
    bail!("render target width {clamped:.0} exceeds i32::MAX; reduce --dpi");
  }
  Ok(clamped as i32)
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

pub fn run_detect_native(input: &str) -> Result<()> {
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

pub fn compute_split_layout(
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

pub fn run_split_native(
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
    split_doc.prune_objects();

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

pub fn init_pdfium() -> Result<Pdfium> {
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

pub fn parse_hex_to_oklab(hex: &str) -> Result<Oklab> {
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

pub fn oklab_distance2(a: Oklab, b: Oklab) -> f32 {
  let dl = a.l - b.l;
  let da = a.a - b.a;
  let db = a.b - b.b;
  dl * dl + da * da + db * db
}

#[derive(Debug, Clone, Copy)]
pub struct PresetConfig {
  pub margin_bias_scale: f32,
  pub strong_threshold: f32,
  pub link_threshold: f32,
  pub hysteresis_enabled: bool,
  pub close_radius_cap: u8,
  pub edge_smoothing_passes: u8,
}

#[derive(Debug)]
pub struct BinarizeResult {
  pub final_bw: GrayImage,
  pub confidence_map: Option<GrayImage>,
  pub seed_ink_map: Option<GrayImage>,
  pub post_hysteresis_map: Option<GrayImage>,
}

#[derive(Debug, Serialize)]
struct PageDebugMetrics {
  page: usize,
  uncertain_pixels: u64,
  seed_ink_pixels: u64,
  final_ink_pixels: u64,
}

pub fn preset_config(preset: PresetArg) -> PresetConfig {
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

pub fn apply_conservative_close<'a>(
  mask_bw: &'a GrayImage,
  close_k: u32,
  preset: PresetArg,
) -> Cow<'a, GrayImage> {
  if close_k == 0 {
    return Cow::Borrowed(mask_bw);
  }

  let config = preset_config(preset);
  let requested_radius = ((close_k.saturating_sub(1)) / 2) as u8;
  let radius = requested_radius.min(config.close_radius_cap);
  if radius == 0 {
    return Cow::Borrowed(mask_bw);
  }

  let w = mask_bw.width();
  let h = mask_bw.height();
  let src = mask_bw.as_raw();

  let mut foreground = GrayImage::new(w, h);
  {
    let dst = foreground.as_mut();
    for i in 0..src.len() {
      dst[i] = 255 - src[i];
    }
  }

  let mut closed = close(&foreground, Norm::L1, radius);
  for _ in 0..config.edge_smoothing_passes {
    closed = median_filter(&closed, 1, 1);
  }
  {
    let buf = closed.as_mut();
    for p in buf.iter_mut() {
      *p = 255 - *p;
    }
  }
  Cow::Owned(closed)
}

#[allow(clippy::too_many_arguments, clippy::excessive_precision)]
pub fn convert_image_to_bw(
  rgb: &image::RgbImage,
  bg_palette: &[Oklab],
  ink_palette: &[Oklab],
  margin: u32,
  invert: bool,
  close_k: u32,
  preset: PresetArg,
  debug: bool,
) -> BinarizeResult {
  let width = rgb.width() as usize;
  let height = rgb.height() as usize;
  let config = preset_config(preset);
  let margin_bias = (margin as f32) * config.margin_bias_scale;

  let mut scores = vec![0.0_f32; width * height];
  let mut confidence = if debug {
    Some(vec![0_u8; width * height])
  } else {
    None
  };
  let mut seeds = if debug {
    Some(vec![0_u8; width * height])
  } else {
    None
  };
  let mut state = vec![0_u8; width * height];

  let mut queue = VecDeque::new();

  let raw = rgb.as_raw();
  let stride = width * 3;

  for y in 0..height {
    let row_base = y * stride;
    for x in 0..width {
      let pb = row_base + x * 3;
      let r_lin = srgb8_to_f32(raw[pb]);
      let g_lin = srgb8_to_f32(raw[pb + 1]);
      let b_lin = srgb8_to_f32(raw[pb + 2]);

      let l = 0.4122214708 * r_lin + 0.5363325363 * g_lin + 0.0514459929 * b_lin;
      let m = 0.2119034982 * r_lin + 0.6806995451 * g_lin + 0.1073969566 * b_lin;
      let s = 0.0883024619 * r_lin + 0.2817188376 * g_lin + 0.6299787005 * b_lin;
      let l_ = l.cbrt();
      let m_ = m.cbrt();
      let s_ = s.cbrt();
      let lab = Oklab::new(
        0.2104542553 * l_ + 0.7936177850 * m_ - 0.0040720468 * s_,
        1.9779984951 * l_ - 2.4285922050 * m_ + 0.4505937099 * s_,
        0.0259040371 * l_ + 0.7827717662 * m_ - 0.8086757660 * s_,
      );

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

      if let Some(ref mut conf) = confidence {
        conf[index] = ((score.abs() / config.strong_threshold).min(1.0) * 255.0) as u8;
      }

      if score >= config.strong_threshold {
        state[index] = 2;
        if let Some(ref mut s) = seeds {
          s[index] = 255;
        }
        if config.hysteresis_enabled {
          queue.push_back((x, y));
        }
      } else if score <= -config.strong_threshold {
        state[index] = 0;
      } else {
        state[index] = 1;
      }
    }
  }

  if config.hysteresis_enabled {
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

  let mut post_hysteresis = if debug {
    Some(GrayImage::new(rgb.width(), rgb.height()))
  } else {
    None
  };

  if let Some(ref mut ph) = post_hysteresis {
    let buf = ph.as_mut();
    for i in 0..width * height {
      buf[i] = if state[i] == 2 { 0 } else { 255 };
    }
  }

  let mut final_bw = if let Some(ref ph) = post_hysteresis {
    apply_conservative_close(ph, close_k, preset).into_owned()
  } else {
    let mut img = GrayImage::new(rgb.width(), rgb.height());
    {
      let buf = img.as_mut();
      for i in 0..width * height {
        buf[i] = if state[i] == 2 { 0 } else { 255 };
      }
    }
    apply_conservative_close(&img, close_k, preset).into_owned()
  };
  if invert {
    for pixel in final_bw.pixels_mut() {
      pixel[0] = 255 - pixel[0];
    }
  }

  BinarizeResult {
    final_bw,
    confidence_map: confidence.map(|v| {
      let mut img = GrayImage::new(rgb.width(), rgb.height());
      img.as_mut().copy_from_slice(&v);
      img
    }),
    seed_ink_map: seeds.map(|v| {
      let mut img = GrayImage::new(rgb.width(), rgb.height());
      img.as_mut().copy_from_slice(&v);
      img
    }),
    post_hysteresis_map: post_hysteresis,
  }
}

pub fn points_to_mm(points: f32) -> f32 {
  points * 25.4 / 72.0
}

pub fn gray_image_to_raw(image: GrayImage) -> RawImage {
  let (width, height) = image.dimensions();
  RawImage {
    width: width as usize,
    height: height as usize,
    data_format: RawImageFormat::R8,
    pixels: RawImageData::U8(image.into_raw()),
    tag: Vec::new(),
  }
}

pub fn write_bw_pages_to_pdf(
  output_path: &str,
  pages: Vec<(GrayImage, f32, f32)>,
  embed_dpi: u32,
) -> Result<()> {
  let mut pdf = PdfDocument::new("make-print-ready-rs output");
  let mut pdf_pages = Vec::with_capacity(pages.len());
  let mut warnings = Vec::<PdfWarnMsg>::new();

  for (bw_page, width_points, height_points) in pages {
    let raw_image = gray_image_to_raw(bw_page);
    let image_id = pdf.add_image(&raw_image);
    let ops = vec![Op::UseXobject {
      id: image_id,
      transform: XObjectTransform {
        translate_x: Some(Pt(0.0)),
        translate_y: Some(Pt(0.0)),
        rotate: None,
        scale_x: None,
        scale_y: None,
        dpi: Some(embed_dpi as f32),
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

pub struct ConvertOptions<'a> {
  pub input: &'a str,
  pub output: &'a str,
  pub dpi: u32,
  pub margin: u32,
  pub invert: bool,
  pub close: u32,
  pub quiet: bool,
  pub flavor: &'a Flavor,
  pub preset: PresetArg,
  pub debug_dir: Option<&'a str>,
}

pub fn run_convert_accurate_preview(opts: ConvertOptions<'_>) -> Result<()> {
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

  let page_count = document.pages().len();
  let progress = ProgressBar::new(page_count as u64);
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

  progress.set_message("rendering pages");

  let rendered: Vec<(image::RgbImage, f32, f32)> = document
    .pages()
    .iter()
    .enumerate()
    .map(|(index, page)| {
      let points_height = page.height().value;
      let points_width = page.width().value;
      let target_width = compute_render_target_width(points_width, opts.dpi)?;
      let render_config = PdfRenderConfig::new().set_target_width(target_width);
      let dynamic_image = page
        .render_with_config(&render_config)
        .with_context(|| format!("failed to render page {}", index + 1))?
        .as_image();
      Ok((dynamic_image.into_rgb8(), points_width, points_height))
    })
    .collect::<Result<Vec<_>>>()?;

  progress.set_message("binarizing pages");

  let binarized: Vec<BinarizeResult> = rendered
    .par_iter()
    .map(|(rgb, _, _)| {
      convert_image_to_bw(
        rgb,
        &bg_palette,
        &ink_palette,
        opts.margin,
        opts.invert,
        opts.close,
        opts.preset,
        debug_dir.is_some(),
      )
    })
    .collect();

  let mut converted_pages: Vec<(GrayImage, f32, f32)> = Vec::with_capacity(page_count as usize);

  for (index, ((_, pw, ph), bin)) in rendered.iter().zip(binarized).enumerate() {
    if let Some(path) = debug_dir {
      let rendered_path = Path::new(path).join(format!("page-{:04}-rendered.png", index + 1));
      rendered[index]
        .0
        .save(&rendered_path)
        .with_context(|| format!("failed to save debug image: {}", rendered_path.display()))?;

      if let Some(ref seed_map) = bin.seed_ink_map {
        let seed_path = Path::new(path).join(format!("page-{:04}-seed-ink.png", index + 1));
        seed_map
          .save(&seed_path)
          .with_context(|| format!("failed to save debug image: {}", seed_path.display()))?;
      }

      if let Some(ref conf_map) = bin.confidence_map {
        let conf_path = Path::new(path).join(format!("page-{:04}-confidence.png", index + 1));
        conf_map
          .save(&conf_path)
          .with_context(|| format!("failed to save debug image: {}", conf_path.display()))?;
      }

      if let Some(ref hyst_map) = bin.post_hysteresis_map {
        let hyst_path = Path::new(path).join(format!("page-{:04}-post-hysteresis.png", index + 1));
        hyst_map
          .save(&hyst_path)
          .with_context(|| format!("failed to save debug image: {}", hyst_path.display()))?;
      }

      let final_path = Path::new(path).join(format!("page-{:04}-final.png", index + 1));
      bin
        .final_bw
        .save(&final_path)
        .with_context(|| format!("failed to save debug image: {}", final_path.display()))?;

      let seed_ink_pixels = bin
        .seed_ink_map
        .as_ref()
        .map(|m| m.pixels().filter(|p| p[0] > 0).count() as u64)
        .unwrap_or(0);
      let uncertain_pixels = bin
        .confidence_map
        .as_ref()
        .map(|m| m.pixels().filter(|p| p[0] < 140).count() as u64)
        .unwrap_or(0);
      let final_ink_pixels = bin.final_bw.pixels().filter(|p| p[0] == 0).count() as u64;

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

    converted_pages.push((bin.final_bw, *pw, *ph));
    progress.inc(1);
  }

  progress.finish_with_message("writing pdf");
  write_bw_pages_to_pdf(opts.output, converted_pages, opts.dpi)?;
  Ok(())
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
  fn close_value_validation_accepts_all_values() {
    for value in [0, 1, 3, 4, 5, 7, 9, 10, 100] {
      assert!(ensure_close_value(value).is_ok());
    }
  }

  #[test]
  fn render_target_width_uses_dpi() {
    assert_eq!(compute_render_target_width(612.0, 300).unwrap(), 2550);
  }
}
