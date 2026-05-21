use anyhow::{bail, Context, Result};
use catppuccin::{Flavor, PALETTE};
use clap::{Parser, ValueEnum};
use image::codecs::png::PngEncoder;
use image::imageops::{resize, FilterType};
use image::{ColorType, ImageEncoder, RgbaImage};
use palette::{IntoColor, Oklab, Srgb};
use std::collections::HashMap;
use std::fs::{self, File};
use std::io::{self, BufWriter, IsTerminal, Read, Write};
use std::path::{Path, PathBuf};
use std::process::ExitCode;

#[derive(Debug, Clone, Copy, PartialEq, Eq, ValueEnum)]
enum FlavorArg {
  Latte,
  Frappe,
  Macchiato,
  Mocha,
}

#[derive(Debug, Parser)]
#[command(name = "catppucinify")]
#[command(about = "Map images onto a Catppuccin palette")]
struct Cli {
  /// Input image path
  input: Option<PathBuf>,

  /// Read encoded image bytes from stdin
  #[arg(long)]
  stdin: bool,

  /// Write PNG output to this path. Use '-' for stdout.
  #[arg(short = 'o', long)]
  output: Option<PathBuf>,

  /// Catppuccin flavor to map into
  #[arg(short = 'f', long, value_enum, default_value_t = FlavorArg::Mocha)]
  flavor: FlavorArg,

  /// Mirror Catppuccin neutral colors after nearest-color mapping
  #[arg(short = 'i', long)]
  invert: bool,

  /// Smoothly upscale before Catppuccin remapping
  #[arg(long)]
  scale: Option<u32>,
}

#[derive(Debug, Clone, PartialEq, Eq)]
enum InputSource {
  Path(PathBuf),
  Stdin,
}

#[derive(Debug, Clone, PartialEq, Eq)]
enum OutputTarget {
  Stdout { explicit: bool },
  Path(PathBuf),
}

#[derive(Debug, Clone, Copy)]
struct PaletteEntry {
  rgb: [u8; 3],
  lab: Oklab,
  accent: bool,
}

#[derive(Debug, Clone, Copy)]
struct QualityConfig {
  neutral_radius2: f32,
  neutral_channel_spread: u8,
  low_confidence_threshold: f32,
  local_bias_strength: f32,
}

const QUALITY_CONFIG: QualityConfig = QualityConfig {
  neutral_radius2: 0.008,
  neutral_channel_spread: 24,
  low_confidence_threshold: 0.12,
  local_bias_strength: 0.00075,
};

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
enum CandidateSet {
  FullPalette,
  NeutralOnly,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
enum NeutralAnchor {
  BlackLike,
  WhiteLike,
}

#[derive(Debug, Clone, Copy)]
struct CandidateMatch {
  best_index: usize,
  best_distance2: f32,
  second_best_distance2: f32,
}

#[derive(Debug, Clone, Copy)]
struct PixelAnalysis {
  lab: Oklab,
  best_index: usize,
  confidence: f32,
  candidate_set: CandidateSet,
  neutral_anchor: Option<NeutralAnchor>,
}

#[derive(Debug)]
struct ResolvedPalette {
  entries: Vec<PaletteEntry>,
  all_indices: Vec<usize>,
  neutral_indices: Vec<usize>,
  invert_map: Vec<usize>,
  base_index: usize,
}

fn flavor_from_arg(flavor: FlavorArg) -> &'static Flavor {
  match flavor {
    FlavorArg::Latte => &PALETTE.latte,
    FlavorArg::Frappe => &PALETTE.frappe,
    FlavorArg::Macchiato => &PALETTE.macchiato,
    FlavorArg::Mocha => &PALETTE.mocha,
  }
}

fn resolve_input_source(cli: &Cli) -> Result<InputSource> {
  match (cli.input.as_ref(), cli.stdin) {
    (Some(_), true) => bail!("provide either INPUT or --stdin, not both"),
    (Some(path), false) => Ok(InputSource::Path(path.clone())),
    (None, true) => Ok(InputSource::Stdin),
    (None, false) => bail!("provide either INPUT or --stdin"),
  }
}

fn resolve_output_target(cli: &Cli) -> OutputTarget {
  match cli.output.as_deref() {
    Some(path) if path == Path::new("-") => OutputTarget::Stdout { explicit: true },
    Some(path) => OutputTarget::Path(path.to_path_buf()),
    None => OutputTarget::Stdout { explicit: false },
  }
}

fn validate_cli(cli: &Cli) -> Result<()> {
  if let Some(scale) = cli.scale {
    if scale <= 1 {
      bail!("--scale must be greater than 1")
    }
  }

  Ok(())
}

fn read_input_bytes(input: &InputSource) -> Result<Vec<u8>> {
  match input {
    InputSource::Path(path) => {
      fs::read(path).with_context(|| format!("failed to read input image: {}", path.display()))
    }
    InputSource::Stdin => {
      if io::stdin().is_terminal() {
        bail!("--stdin was set, but stdin is a terminal; pipe image bytes or provide INPUT")
      }

      let mut bytes = Vec::new();
      io::stdin()
        .lock()
        .read_to_end(&mut bytes)
        .context("failed to read stdin")?;
      if bytes.is_empty() {
        bail!("no image bytes received on stdin")
      }
      Ok(bytes)
    }
  }
}

fn rgb_to_oklab(rgb: [u8; 3]) -> Oklab {
  Srgb::new(
    rgb[0] as f32 / 255.0,
    rgb[1] as f32 / 255.0,
    rgb[2] as f32 / 255.0,
  )
  .into_linear()
  .into_color()
}

fn oklab_distance2(a: Oklab, b: Oklab) -> f32 {
  let dl = a.l - b.l;
  let da = a.a - b.a;
  let db = a.b - b.b;
  dl * dl + da * da + db * db
}

fn build_palette(flavor: &'static Flavor) -> ResolvedPalette {
  let mut entries = Vec::new();
  for color in flavor.iter() {
    let rgb = [color.rgb.r, color.rgb.g, color.rgb.b];
    entries.push(PaletteEntry {
      rgb,
      lab: rgb_to_oklab(rgb),
      accent: color.accent,
    });
  }

  let all_indices: Vec<usize> = (0..entries.len()).collect();
  let mut invert_map: Vec<usize> = (0..entries.len()).collect();
  let base_rgb = [
    flavor.colors.base.rgb.r,
    flavor.colors.base.rgb.g,
    flavor.colors.base.rgb.b,
  ];
  let base_index = entries
    .iter()
    .position(|entry| entry.rgb == base_rgb)
    .expect("base color should always be present in the resolved palette");
  let mut neutral_indices: Vec<usize> = entries
    .iter()
    .enumerate()
    .filter_map(|(index, entry)| (!entry.accent).then_some(index))
    .collect();
  neutral_indices.sort_by(|left, right| entries[*left].lab.l.total_cmp(&entries[*right].lab.l));

  for (position, &from_index) in neutral_indices.iter().enumerate() {
    let to_index = neutral_indices[neutral_indices.len() - 1 - position];
    invert_map[from_index] = to_index;
  }

  ResolvedPalette {
    entries,
    all_indices,
    neutral_indices,
    invert_map,
    base_index,
  }
}

fn candidate_indices<'a>(palette: &'a ResolvedPalette, candidate_set: CandidateSet) -> &'a [usize] {
  match candidate_set {
    CandidateSet::FullPalette => &palette.all_indices,
    CandidateSet::NeutralOnly => &palette.neutral_indices,
  }
}

fn classify_neutral_anchor(
  rgb: [u8; 3],
  lab: Oklab,
  pure_black: Oklab,
  pure_white: Oklab,
  config: QualityConfig,
) -> Option<NeutralAnchor> {
  let channel_min = rgb.into_iter().min().expect("rgb must have channels");
  let channel_max = rgb.into_iter().max().expect("rgb must have channels");
  if channel_max.saturating_sub(channel_min) > config.neutral_channel_spread {
    return None;
  }

  let black_distance2 = oklab_distance2(lab, pure_black);
  let white_distance2 = oklab_distance2(lab, pure_white);

  if black_distance2.min(white_distance2) <= config.neutral_radius2 {
    Some(if white_distance2 < black_distance2 {
      NeutralAnchor::WhiteLike
    } else {
      NeutralAnchor::BlackLike
    })
  } else {
    None
  }
}

fn nearest_palette_candidate(
  palette: &ResolvedPalette,
  candidate_set: CandidateSet,
  lab: Oklab,
) -> CandidateMatch {
  let mut candidate_indices = candidate_indices(palette, candidate_set).iter().copied();
  let best_index = candidate_indices
    .next()
    .expect("candidate sets must contain at least one color");
  let mut best_distance2 = oklab_distance2(lab, palette.entries[best_index].lab);
  let mut second_best_distance2 = f32::INFINITY;
  let mut best_index = best_index;

  for index in candidate_indices {
    let distance2 = oklab_distance2(lab, palette.entries[index].lab);
    if distance2 < best_distance2 {
      second_best_distance2 = best_distance2;
      best_distance2 = distance2;
      best_index = index;
    } else if distance2 < second_best_distance2 {
      second_best_distance2 = distance2;
    }
  }

  CandidateMatch {
    best_index,
    best_distance2,
    second_best_distance2,
  }
}

fn compute_confidence(best_distance2: f32, second_best_distance2: f32) -> f32 {
  if !second_best_distance2.is_finite() {
    return 1.0;
  }

  ((second_best_distance2 - best_distance2) / (second_best_distance2 + 1e-6)).clamp(0.0, 1.0)
}

fn analyze_rgb(
  rgb: [u8; 3],
  palette: &ResolvedPalette,
  config: QualityConfig,
  pure_black: Oklab,
  pure_white: Oklab,
) -> PixelAnalysis {
  let lab = rgb_to_oklab(rgb);
  let neutral_anchor = classify_neutral_anchor(rgb, lab, pure_black, pure_white, config);
  let candidate_set = if neutral_anchor.is_some() {
    CandidateSet::NeutralOnly
  } else {
    CandidateSet::FullPalette
  };
  let matched = nearest_palette_candidate(palette, candidate_set, lab);

  PixelAnalysis {
    lab,
    best_index: matched.best_index,
    confidence: compute_confidence(matched.best_distance2, matched.second_best_distance2),
    candidate_set,
    neutral_anchor,
  }
}

fn analyze_pixels(
  raw: &[u8],
  palette: &ResolvedPalette,
  config: QualityConfig,
) -> Vec<Option<PixelAnalysis>> {
  let mut analyses = Vec::with_capacity(raw.len() / 4);
  let mut cache = HashMap::with_capacity(raw.len() / 4);
  let pure_black = rgb_to_oklab([0, 0, 0]);
  let pure_white = rgb_to_oklab([255, 255, 255]);

  for pixel in raw.chunks_exact(4) {
    if pixel[3] == 0 {
      analyses.push(None);
      continue;
    }

    let rgb = [pixel[0], pixel[1], pixel[2]];
    let analysis = if let Some(analysis) = cache.get(&pack_rgb(rgb)) {
      *analysis
    } else {
      let analysis = analyze_rgb(rgb, palette, config, pure_black, pure_white);
      cache.insert(pack_rgb(rgb), analysis);
      analysis
    };
    analyses.push(Some(analysis));
  }

  analyses
}

fn apply_local_confidence_bias(
  width: usize,
  height: usize,
  palette: &ResolvedPalette,
  analyses: &[Option<PixelAnalysis>],
  config: QualityConfig,
) -> Vec<Option<usize>> {
  let mut resolved_indices: Vec<Option<usize>> = analyses
    .iter()
    .map(|analysis| analysis.map(|analysis| analysis.best_index))
    .collect();
  let mut neighbor_votes = vec![0.0_f32; palette.entries.len()];

  for y in 0..height {
    for x in 0..width {
      let index = y * width + x;
      let Some(analysis) = analyses[index] else {
        continue;
      };
      if analysis.confidence >= config.low_confidence_threshold {
        continue;
      }

      neighbor_votes.fill(0.0);
      let mut has_neighbor_votes = false;
      let x0 = x.saturating_sub(1);
      let y0 = y.saturating_sub(1);
      let x1 = (x + 1).min(width - 1);
      let y1 = (y + 1).min(height - 1);

      for ny in y0..=y1 {
        for nx in x0..=x1 {
          if nx == x && ny == y {
            continue;
          }

          let neighbor_index = ny * width + nx;
          let Some(neighbor) = analyses[neighbor_index] else {
            continue;
          };
          neighbor_votes[neighbor.best_index] += neighbor.confidence;
          has_neighbor_votes = true;
        }
      }

      if !has_neighbor_votes {
        continue;
      }

      let mut best_index = analysis.best_index;
      let mut best_score = f32::INFINITY;
      for &candidate_index in candidate_indices(palette, analysis.candidate_set) {
        let distance2 = oklab_distance2(analysis.lab, palette.entries[candidate_index].lab);
        let score = distance2 - (config.local_bias_strength * neighbor_votes[candidate_index]);
        if score < best_score {
          best_score = score;
          best_index = candidate_index;
        }
      }

      resolved_indices[index] = Some(best_index);
    }
  }

  resolved_indices
}

fn pack_rgb(rgb: [u8; 3]) -> u32 {
  (u32::from(rgb[0]) << 16) | (u32::from(rgb[1]) << 8) | u32::from(rgb[2])
}

fn remap_image(mut image: RgbaImage, palette: &ResolvedPalette, invert: bool) -> RgbaImage {
  let width = image.width() as usize;
  let height = image.height() as usize;
  let raw = image.as_mut();
  let analyses = analyze_pixels(raw, palette, QUALITY_CONFIG);
  let resolved_indices =
    apply_local_confidence_bias(width, height, palette, &analyses, QUALITY_CONFIG);

  for ((pixel, analysis), resolved_index) in raw
    .chunks_exact_mut(4)
    .zip(analyses.iter())
    .zip(resolved_indices.iter())
  {
    let Some(analysis) = *analysis else {
      continue;
    };

    let resolved_index = resolved_index.expect("visible pixels must have a resolved palette index");
    let resolved_index = if invert {
      if analysis.neutral_anchor == Some(NeutralAnchor::WhiteLike) {
        palette.base_index
      } else {
        palette.invert_map[resolved_index]
      }
    } else {
      resolved_index
    };
    let mapped = palette.entries[resolved_index].rgb;

    pixel[0] = mapped[0];
    pixel[1] = mapped[1];
    pixel[2] = mapped[2];
  }

  image
}

fn decode_image(bytes: &[u8]) -> Result<RgbaImage> {
  Ok(
    image::load_from_memory(bytes)
      .context("failed to decode input image")?
      .into_rgba8(),
  )
}

fn upscale_image(image: &RgbaImage, scale: u32) -> Result<RgbaImage> {
  let target_width = image
    .width()
    .checked_mul(scale)
    .context("scaled image width overflowed u32")?;
  let target_height = image
    .height()
    .checked_mul(scale)
    .context("scaled image height overflowed u32")?;

  Ok(resize(
    image,
    target_width,
    target_height,
    FilterType::CatmullRom,
  ))
}

fn maybe_upscale_image(image: RgbaImage, scale: Option<u32>) -> Result<RgbaImage> {
  match scale {
    Some(scale) => upscale_image(&image, scale),
    None => Ok(image),
  }
}

fn write_png<W: Write>(writer: W, image: &RgbaImage) -> Result<()> {
  let encoder = PngEncoder::new(writer);
  encoder
    .write_image(
      image.as_raw(),
      image.width(),
      image.height(),
      ColorType::Rgba8.into(),
    )
    .context("failed to encode PNG")
}

fn write_output(output: &OutputTarget, image: &RgbaImage) -> Result<()> {
  match output {
    OutputTarget::Stdout { explicit } => {
      if !explicit && io::stdout().is_terminal() {
        bail!("refusing to write PNG bytes to an interactive terminal; use --output <path> or --output -")
      }

      let stdout = io::stdout();
      let handle = stdout.lock();
      let writer = BufWriter::new(handle);
      write_png(writer, image)
    }
    OutputTarget::Path(path) => {
      let file = File::create(path)
        .with_context(|| format!("failed to create output file: {}", path.display()))?;
      let writer = BufWriter::new(file);
      write_png(writer, image)
    }
  }
}

fn run() -> Result<()> {
  let cli = Cli::parse();
  validate_cli(&cli)?;
  let input = resolve_input_source(&cli)?;
  let output = resolve_output_target(&cli);
  let flavor = flavor_from_arg(cli.flavor);
  let palette = build_palette(flavor);

  let bytes = read_input_bytes(&input)?;
  let image = decode_image(&bytes)?;
  let image = maybe_upscale_image(image, cli.scale)?;
  let remapped = remap_image(image, &palette, cli.invert);
  write_output(&output, &remapped)
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
  use image::Rgba;

  fn cli_from(args: &[&str]) -> Cli {
    Cli::try_parse_from(args).expect("cli should parse")
  }

  fn cli_try(args: &[&str]) -> std::result::Result<Cli, clap::Error> {
    Cli::try_parse_from(args)
  }

  fn remap_pixel(flavor: &'static Flavor, rgba: [u8; 4], invert: bool) -> [u8; 4] {
    let image = RgbaImage::from_pixel(1, 1, image::Rgba(rgba));
    let palette = build_palette(flavor);
    let image = remap_image(image, &palette, invert);
    image.get_pixel(0, 0).0
  }

  fn palette_index_for_rgb(palette: &ResolvedPalette, rgb: [u8; 3]) -> usize {
    palette
      .entries
      .iter()
      .position(|entry| entry.rgb == rgb)
      .expect("output should always be a palette color")
  }

  fn midpoint_lab(a: Oklab, b: Oklab) -> Oklab {
    Oklab {
      l: (a.l + b.l) / 2.0,
      a: (a.a + b.a) / 2.0,
      b: (a.b + b.b) / 2.0,
    }
  }

  fn remap_image_for_test(
    flavor: &'static Flavor,
    image: RgbaImage,
    invert: bool,
    scale: Option<u32>,
  ) -> RgbaImage {
    let palette = build_palette(flavor);
    let image = maybe_upscale_image(image, scale).expect("upscale should succeed in tests");
    remap_image(image, &palette, invert)
  }

  fn assert_image_is_palette_only(flavor: &'static Flavor, image: &RgbaImage) {
    let palette = build_palette(flavor);
    for pixel in image.pixels() {
      if pixel[3] == 0 {
        continue;
      }

      let rgb = [pixel[0], pixel[1], pixel[2]];
      assert!(palette.entries.iter().any(|entry| entry.rgb == rgb));
    }
  }

  #[test]
  fn cli_defaults_to_mocha() {
    let cli = cli_from(&["catppucinify", "input.png"]);
    assert_eq!(cli.flavor, FlavorArg::Mocha);
    assert_eq!(cli.input, Some(PathBuf::from("input.png")));
    assert!(!cli.stdin);
    assert_eq!(cli.scale, None);
  }

  #[test]
  fn cli_accepts_scale_flag() {
    let cli = cli_from(&["catppucinify", "input.png", "--scale", "3"]);
    assert_eq!(cli.scale, Some(3));
  }

  #[test]
  fn validate_cli_rejects_scale_zero() {
    let cli = cli_from(&["catppucinify", "input.png", "--scale", "0"]);
    assert!(validate_cli(&cli).is_err());
  }

  #[test]
  fn validate_cli_rejects_scale_one() {
    let cli = cli_from(&["catppucinify", "input.png", "--scale", "1"]);
    assert!(validate_cli(&cli).is_err());
  }

  #[test]
  fn cli_requires_scale_value() {
    assert!(cli_try(&["catppucinify", "input.png", "--scale"]).is_err());
  }

  #[test]
  fn resolve_input_accepts_path() {
    let cli = cli_from(&["catppucinify", "input.png"]);
    assert_eq!(
      resolve_input_source(&cli).unwrap(),
      InputSource::Path(PathBuf::from("input.png"))
    );
  }

  #[test]
  fn resolve_input_accepts_stdin() {
    let cli = cli_from(&["catppucinify", "--stdin"]);
    assert_eq!(resolve_input_source(&cli).unwrap(), InputSource::Stdin);
  }

  #[test]
  fn resolve_input_rejects_path_and_stdin() {
    let cli = cli_from(&["catppucinify", "input.png", "--stdin"]);
    assert!(resolve_input_source(&cli).is_err());
  }

  #[test]
  fn resolve_input_rejects_missing_input() {
    let cli = cli_from(&["catppucinify"]);
    assert!(resolve_input_source(&cli).is_err());
  }

  #[test]
  fn resolve_output_treats_dash_as_explicit_stdout() {
    let cli = cli_from(&["catppucinify", "input.png", "--output", "-"]);
    assert_eq!(
      resolve_output_target(&cli),
      OutputTarget::Stdout { explicit: true }
    );
  }

  #[test]
  fn upscale_image_changes_dimensions() {
    let image = RgbaImage::from_pixel(2, 3, Rgba([40, 50, 60, 255]));
    let scaled = upscale_image(&image, 4).unwrap();
    assert_eq!(scaled.dimensions(), (8, 12));
  }

  #[test]
  fn maybe_upscale_image_keeps_dimensions_without_scale() {
    let image = RgbaImage::from_pixel(2, 3, Rgba([40, 50, 60, 255]));
    let scaled = maybe_upscale_image(image, None).unwrap();
    assert_eq!(scaled.dimensions(), (2, 3));
  }

  #[test]
  fn maybe_upscale_image_scales_dimensions_with_scale_flag() {
    let image = RgbaImage::from_pixel(2, 3, Rgba([40, 50, 60, 255]));
    let scaled = maybe_upscale_image(image, Some(3)).unwrap();
    assert_eq!(scaled.dimensions(), (6, 9));
  }

  #[test]
  fn palette_has_expected_accent_and_neutral_counts() {
    for flavor in [
      &PALETTE.latte,
      &PALETTE.frappe,
      &PALETTE.macchiato,
      &PALETTE.mocha,
    ] {
      let palette = build_palette(flavor);
      let accent_count = palette.entries.iter().filter(|entry| entry.accent).count();
      let neutral_count = palette.entries.iter().filter(|entry| !entry.accent).count();
      assert_eq!(accent_count, 14);
      assert_eq!(neutral_count, 12);
      assert_eq!(palette.neutral_indices.len(), 12);
    }
  }

  #[test]
  fn neutral_indices_only_reference_neutral_colors() {
    for flavor in [
      &PALETTE.latte,
      &PALETTE.frappe,
      &PALETTE.macchiato,
      &PALETTE.mocha,
    ] {
      let palette = build_palette(flavor);
      for &index in &palette.neutral_indices {
        assert!(!palette.entries[index].accent);
      }
    }
  }

  #[test]
  fn neutral_invert_mapping_is_symmetric() {
    for flavor in [
      &PALETTE.latte,
      &PALETTE.frappe,
      &PALETTE.macchiato,
      &PALETTE.mocha,
    ] {
      let palette = build_palette(flavor);
      for (index, entry) in palette.entries.iter().enumerate() {
        if entry.accent {
          assert_eq!(palette.invert_map[index], index);
        } else {
          let mirrored = palette.invert_map[index];
          assert_eq!(palette.invert_map[mirrored], index);
        }
      }
    }
  }

  #[test]
  fn exact_palette_colors_map_to_themselves_without_invert() {
    for flavor in [
      &PALETTE.latte,
      &PALETTE.frappe,
      &PALETTE.macchiato,
      &PALETTE.mocha,
    ] {
      for color in flavor.iter() {
        let rgba = [color.rgb.r, color.rgb.g, color.rgb.b, 203];
        assert_eq!(remap_pixel(flavor, rgba, false), rgba);
      }
    }
  }

  #[test]
  fn near_black_pixels_use_neutral_subset() {
    let rgba = [8, 3, 12, 255];
    for flavor in [
      &PALETTE.latte,
      &PALETTE.frappe,
      &PALETTE.macchiato,
      &PALETTE.mocha,
    ] {
      let palette = build_palette(flavor);
      let output = remap_pixel(flavor, rgba, false);
      let index = palette_index_for_rgb(&palette, [output[0], output[1], output[2]]);
      assert!(!palette.entries[index].accent);
    }
  }

  #[test]
  fn near_white_pixels_use_neutral_subset() {
    let rgba = [248, 252, 245, 255];
    for flavor in [
      &PALETTE.latte,
      &PALETTE.frappe,
      &PALETTE.macchiato,
      &PALETTE.mocha,
    ] {
      let palette = build_palette(flavor);
      let output = remap_pixel(flavor, rgba, false);
      let index = palette_index_for_rgb(&palette, [output[0], output[1], output[2]]);
      assert!(!palette.entries[index].accent);
    }
  }

  #[test]
  fn accents_do_not_invert() {
    for flavor in [
      &PALETTE.latte,
      &PALETTE.frappe,
      &PALETTE.macchiato,
      &PALETTE.mocha,
    ] {
      let palette = build_palette(flavor);
      for entry in palette.entries.iter().filter(|entry| entry.accent) {
        let rgba = [entry.rgb[0], entry.rgb[1], entry.rgb[2], 255];
        assert_eq!(remap_pixel(flavor, rgba, true), rgba);
      }
    }
  }

  #[test]
  fn invert_swaps_lightest_and_darkest_neutrals() {
    for flavor in [
      &PALETTE.latte,
      &PALETTE.frappe,
      &PALETTE.macchiato,
      &PALETTE.mocha,
    ] {
      let palette = build_palette(flavor);
      let mut neutral_indices: Vec<usize> = palette
        .entries
        .iter()
        .enumerate()
        .filter_map(|(index, entry)| (!entry.accent).then_some(index))
        .collect();
      neutral_indices.sort_by(|left, right| {
        palette.entries[*left]
          .lab
          .l
          .total_cmp(&palette.entries[*right].lab.l)
      });

      let darkest = palette.entries[neutral_indices[0]];
      let lightest = palette.entries[*neutral_indices.last().expect("neutral colors present")];

      let darkest_rgba = [darkest.rgb[0], darkest.rgb[1], darkest.rgb[2], 255];
      let lightest_rgba = [lightest.rgb[0], lightest.rgb[1], lightest.rgb[2], 255];

      assert_eq!(remap_pixel(flavor, darkest_rgba, true), lightest_rgba);
    }
  }

  #[test]
  fn invert_white_like_neutrals_prefer_base() {
    let rgba = [248, 252, 245, 255];
    for flavor in [
      &PALETTE.latte,
      &PALETTE.frappe,
      &PALETTE.macchiato,
      &PALETTE.mocha,
    ] {
      let expected = [
        flavor.colors.base.rgb.r,
        flavor.colors.base.rgb.g,
        flavor.colors.base.rgb.b,
        255,
      ];
      assert_eq!(remap_pixel(flavor, rgba, true), expected);
    }
  }

  #[test]
  fn invert_mirrors_neutral_first_black_classification() {
    let rgba = [8, 3, 12, 255];
    for flavor in [
      &PALETTE.latte,
      &PALETTE.frappe,
      &PALETTE.macchiato,
      &PALETTE.mocha,
    ] {
      let palette = build_palette(flavor);
      let normal = remap_pixel(flavor, rgba, false);
      let inverted = remap_pixel(flavor, rgba, true);
      let normal_index = palette_index_for_rgb(&palette, [normal[0], normal[1], normal[2]]);
      let inverted_index = palette_index_for_rgb(&palette, [inverted[0], inverted[1], inverted[2]]);

      assert!(!palette.entries[normal_index].accent);
      assert!(!palette.entries[inverted_index].accent);
      assert_eq!(inverted_index, palette.invert_map[normal_index]);
    }
  }

  #[test]
  fn saturated_pixels_outside_neutral_radius_can_still_map_to_accents() {
    let rgba = [235, 80, 120, 255];
    for flavor in [
      &PALETTE.latte,
      &PALETTE.frappe,
      &PALETTE.macchiato,
      &PALETTE.mocha,
    ] {
      let palette = build_palette(flavor);
      let output = remap_pixel(flavor, rgba, false);
      let index = palette_index_for_rgb(&palette, [output[0], output[1], output[2]]);
      assert!(palette.entries[index].accent);
    }
  }

  #[test]
  fn local_confidence_bias_can_reinforce_an_ambiguous_cluster() {
    let palette = build_palette(&PALETTE.mocha);
    let accent_a = palette
      .entries
      .iter()
      .position(|entry| {
        entry.rgb
          == [
            PALETTE.mocha.colors.red.rgb.r,
            PALETTE.mocha.colors.red.rgb.g,
            PALETTE.mocha.colors.red.rgb.b,
          ]
      })
      .expect("red present");
    let accent_b = palette
      .entries
      .iter()
      .position(|entry| {
        entry.rgb
          == [
            PALETTE.mocha.colors.maroon.rgb.r,
            PALETTE.mocha.colors.maroon.rgb.g,
            PALETTE.mocha.colors.maroon.rgb.b,
          ]
      })
      .expect("maroon present");
    let center_lab = midpoint_lab(palette.entries[accent_a].lab, palette.entries[accent_b].lab);
    let mut analyses = vec![
      Some(PixelAnalysis {
        lab: palette.entries[accent_b].lab,
        best_index: accent_b,
        confidence: 1.0,
        candidate_set: CandidateSet::FullPalette,
        neutral_anchor: None,
      });
      9
    ];
    analyses[4] = Some(PixelAnalysis {
      lab: center_lab,
      best_index: accent_a,
      confidence: 0.01,
      candidate_set: CandidateSet::FullPalette,
      neutral_anchor: None,
    });

    let resolved = apply_local_confidence_bias(3, 3, &palette, &analyses, QUALITY_CONFIG);
    assert_eq!(resolved[4], Some(accent_b));
  }

  #[test]
  fn scaled_output_remains_palette_only() {
    let mut image = RgbaImage::new(2, 2);
    image.put_pixel(0, 0, Rgba([250, 250, 250, 255]));
    image.put_pixel(1, 0, Rgba([25, 20, 35, 255]));
    image.put_pixel(0, 1, Rgba([180, 90, 120, 255]));
    image.put_pixel(1, 1, Rgba([80, 180, 210, 255]));

    let remapped = remap_image_for_test(&PALETTE.mocha, image, false, Some(2));
    assert_eq!(remapped.dimensions(), (4, 4));
    assert_image_is_palette_only(&PALETTE.mocha, &remapped);
  }

  #[test]
  fn scaled_invert_output_remains_palette_only() {
    let mut image = RgbaImage::new(2, 2);
    image.put_pixel(0, 0, Rgba([245, 245, 240, 255]));
    image.put_pixel(1, 0, Rgba([15, 12, 20, 255]));
    image.put_pixel(0, 1, Rgba([140, 110, 90, 255]));
    image.put_pixel(1, 1, Rgba([110, 150, 220, 255]));

    let remapped = remap_image_for_test(&PALETTE.mocha, image, true, Some(2));
    assert_eq!(remapped.dimensions(), (4, 4));
    assert_image_is_palette_only(&PALETTE.mocha, &remapped);
  }

  #[test]
  fn transparent_pixels_remain_unchanged() {
    let rgba = [1, 2, 3, 0];
    assert_eq!(remap_pixel(&PALETTE.mocha, rgba, true), rgba);
  }

  #[test]
  fn alpha_is_preserved_for_visible_pixels() {
    let rgba = [250, 250, 250, 17];
    assert_eq!(remap_pixel(&PALETTE.mocha, rgba, true)[3], 17);
  }

  #[test]
  fn scaled_uniform_partial_alpha_is_preserved() {
    let image = RgbaImage::from_pixel(1, 1, Rgba([240, 240, 240, 17]));
    let remapped = remap_image_for_test(&PALETTE.mocha, image, true, Some(3));
    assert_eq!(remapped.dimensions(), (3, 3));
    for pixel in remapped.pixels() {
      assert_eq!(pixel[3], 17);
    }
  }
}
