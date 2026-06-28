use std::process::ExitCode;

use anyhow::{Result, bail};
use clap::{Parser, Subcommand, ValueEnum};
use make_print_ready_rs::*;

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
    margin: u32,

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
    #[arg(long, value_enum, default_value_t = FlavorArgCli::Mocha)]
    flavor: FlavorArgCli,

    /// Trade-off preset (quality targets cleaner, thinner handwriting)
    #[arg(long, value_enum, default_value_t = PresetArgCli::Quality)]
    preset: PresetArgCli,

    /// Write debug artifacts into this directory
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

#[derive(Debug, Clone, Copy, PartialEq, Eq, ValueEnum)]
enum FlavorArgCli {
  Latte,
  Frappe,
  Macchiato,
  Mocha,
}

impl From<FlavorArgCli> for FlavorArg {
  fn from(v: FlavorArgCli) -> Self {
    match v {
      FlavorArgCli::Latte => FlavorArg::Latte,
      FlavorArgCli::Frappe => FlavorArg::Frappe,
      FlavorArgCli::Macchiato => FlavorArg::Macchiato,
      FlavorArgCli::Mocha => FlavorArg::Mocha,
    }
  }
}

#[derive(Debug, Clone, Copy, PartialEq, Eq, ValueEnum)]
enum PresetArgCli {
  Quality,
  Fast,
}

impl From<PresetArgCli> for PresetArg {
  fn from(v: PresetArgCli) -> Self {
    match v {
      PresetArgCli::Quality => PresetArg::Quality,
      PresetArgCli::Fast => PresetArg::Fast,
    }
  }
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
      preset,
      debug,
    } => {
      ensure_close_value(close)?;
      let selected_flavor = flavor_from_arg(flavor.into());
      let background_hex = [
        selected_flavor.colors.base.hex,
        selected_flavor.colors.mantle.hex,
        selected_flavor.colors.crust.hex,
      ];

      if !quiet {
        eprintln!(
          "[make-print-ready-rs] preset={:?} flavor={} bg={:?}",
          preset, selected_flavor.name, background_hex
        );
      }

      if debug.is_some() && !quiet {
        eprintln!(
          "[make-print-ready-rs] debug mode enabled; writing per-page PNGs to the debug directory"
        );
      }

      run_convert_accurate_preview(ConvertOptions {
        input: &input,
        output: &output,
        dpi,
        margin,
        invert,
        close,
        quiet,
        flavor: selected_flavor,
        preset: preset.into(),
        debug_dir: debug.as_deref(),
      })?;
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
