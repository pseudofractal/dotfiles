{pkgs, inputs, ...}: let
  system = pkgs.stdenv.hostPlatform.system;
  mnemosyneSettings = {
    dependency_graph = false;
    ignore = [
      "*.png"
      "*.jpg"
      "*.jpeg"
      "*.gif"
      "*.bmp"
      "*.ico"
      "*.svg"
      "*.mp4"
      "*.avi"
      "*.mov"
      "*.mkv"
      "*.mp3"
      "*.wav"
      "*.ogg"
      "*.zip"
      "*.tar"
      "*.gz"
      "*.bz2"
      "*.pack"
      "*.ttf"
      "*.otf"
      "*.woff"
      "*.woff2"
      "*.eot"
      "*.exe"
      "*.dll"
      "*.so"
      "*.a"
      "*.o"
      "*.jar"
      "*.class"
      "*.fits"
      "*.rev"
      "*.idx"
      "*.ctab"
      "*.npy"
      "*.po"
      "*.git"
    ];
  };
in {
  home.packages = [
    inputs.mnemosyne.packages.${system}.default
  ];

  xdg.configFile."mnemosyne/mnemosyne.config.jsonc".source =
    (pkgs.formats.json {}).generate "mnemosyne.config.json" mnemosyneSettings;
}
