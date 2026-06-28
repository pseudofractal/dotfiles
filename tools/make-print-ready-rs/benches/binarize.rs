use criterion::{Criterion, criterion_group, criterion_main};
use image::{Rgb, RgbImage};
use make_print_ready_rs::*;
use palette::Oklab;
use rayon::prelude::*;

fn make_palette() -> (Vec<Oklab>, Vec<Oklab>) {
  let mocha = &catppuccin::PALETTE.mocha;
  let bg_hex = [
    mocha.colors.base.hex.to_string(),
    mocha.colors.mantle.hex.to_string(),
    mocha.colors.crust.hex.to_string(),
  ];
  let bg: Vec<Oklab> = bg_hex
    .iter()
    .map(|h| parse_hex_to_oklab(h).unwrap())
    .collect();
  let ink: Vec<Oklab> = mocha
    .iter()
    .filter(|c| !bg_hex.contains(&c.hex.to_string()))
    .map(|c| parse_hex_to_oklab(&c.hex.to_string()).unwrap())
    .collect();
  (bg, ink)
}

fn make_image(w: u32, h: u32) -> RgbImage {
  let mut img = RgbImage::new(w, h);
  for y in 0..h {
    for x in 0..w {
      let r = ((x * 7 + y * 3) % 256) as u8;
      let g = ((x * 11 + y * 5 + 100) % 256) as u8;
      let b = ((x * 13 + y * 7 + 200) % 256) as u8;
      img.put_pixel(x, y, Rgb([r, g, b]));
    }
  }
  img
}

fn bench_binarize_small(c: &mut Criterion) {
  let (bg, ink) = make_palette();
  let img = make_image(800, 600);
  c.bench_function("binarize_800x600", |b| {
    b.iter(|| convert_image_to_bw(&img, &bg, &ink, 0, false, 0, PresetArg::Quality, false));
  });
}

fn bench_binarize_medium(c: &mut Criterion) {
  let (bg, ink) = make_palette();
  let img = make_image(2550, 3300);
  c.bench_function("binarize_2550x3300", |b| {
    b.iter(|| convert_image_to_bw(&img, &bg, &ink, 0, false, 0, PresetArg::Quality, false));
  });
}

fn bench_binarize_large(c: &mut Criterion) {
  let (bg, ink) = make_palette();
  let img = make_image(5100, 6600);
  c.bench_function("binarize_5100x6600", |b| {
    b.iter(|| convert_image_to_bw(&img, &bg, &ink, 0, false, 0, PresetArg::Quality, false));
  });
}

fn bench_parallel_4_pages(c: &mut Criterion) {
  let (bg, ink) = make_palette();
  let imgs: Vec<RgbImage> = (0..4).map(|i| make_image(5100, 6600 + i * 100)).collect();
  c.bench_function("parallel_4x_600dpi", |b| {
    b.iter(|| {
      imgs
        .par_iter()
        .map(|rgb| convert_image_to_bw(rgb, &bg, &ink, 0, false, 0, PresetArg::Quality, false))
        .collect::<Vec<_>>()
    });
  });
}

fn bench_parallel_8_pages(c: &mut Criterion) {
  let (bg, ink) = make_palette();
  let imgs: Vec<RgbImage> = (0..8).map(|i| make_image(5100, 6600 + i * 100)).collect();
  c.bench_function("parallel_8x_600dpi", |b| {
    b.iter(|| {
      imgs
        .par_iter()
        .map(|rgb| convert_image_to_bw(rgb, &bg, &ink, 0, false, 0, PresetArg::Quality, false))
        .collect::<Vec<_>>()
    });
  });
}

criterion_group!(
  benches,
  bench_binarize_small,
  bench_binarize_medium,
  bench_binarize_large,
  bench_parallel_4_pages,
  bench_parallel_8_pages,
);
criterion_main!(benches);
