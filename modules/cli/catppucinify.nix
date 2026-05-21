{pkgs, ...}: let
  catppucinifyRust = pkgs.rustPlatform.buildRustPackage {
    pname = "catppucinify";
    version = "0.1.0";
    src = ../../tools/catppucinify-rs;
    cargoLock.lockFile = ../../tools/catppucinify-rs/Cargo.lock;
  };
in {
  home.packages = [
    catppucinifyRust
  ];
}
