{pkgs}: pkgs.rustPlatform.buildRustPackage {
  pname = "catppucinify";
  version = "0.1.0";
  src = ./catppucinify-rs;
  cargoLock.lockFile = ./catppucinify-rs/Cargo.lock;
}
