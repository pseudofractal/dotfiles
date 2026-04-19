{
  config,
  lib,
  pkgs,
  inputs,
  ...
}: let
  shiryokuPackage = pkgs.rustPlatform.buildRustPackage {
    pname = "shiryoku";
    version = "1.0.0";
    src = inputs.shiryoku;
    cargoLock.lockFile = "${inputs.shiryoku}/Cargo.lock";
    nativeBuildInputs = [
      pkgs.pkg-config
    ];
    buildInputs = [
      pkgs.openssl
      pkgs.wayland
      pkgs.libxkbcommon
      pkgs.libx11
      pkgs.libxcursor
      pkgs.libxi
      pkgs.libxrandr
    ];
  };
in {
  home.packages = [
    shiryokuPackage
  ];

  sops.secrets.shiryoku_config = {};
  xdg.configFile."shiryoku/config.json".source =
    lib.mkForce (config.lib.file.mkOutOfStoreSymlink config.sops.secrets.shiryoku_config.path);
}
