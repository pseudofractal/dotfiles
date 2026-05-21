{pkgs, inputs, ...}: let
  system = pkgs.stdenv.hostPlatform.system;
  mnemosyneSettings = {
    dependency_graph = false;
    ignore = [
      # keep-sorted start
      "*.a"
      "*.avi"
      "*.bmp"
      "*.bz2"
      "*.class"
      "*.ctab"
      "*.dll"
      "*.eot"
      "*.exe"
      "*.fits"
      "*.gif"
      "*.gz"
      "*.ico"
      "*.idx"
      "*.jar"
      "*.jpg"
      "*.jpeg"
      "*.mkv"
      "*.mov"
      "*.mp3"
      "*.mp4"
      "*.npy"
      "*.o"
      "*.otf"
      "*.ogg"
      "*.pack"
      "*.png"
      "*.po"
      "*.rev"
      "*.so"
      "*.svg"
      "*.tar"
      "*.ttf"
      "*.wav"
      "*.woff"
      "*.woff2"
      "*.zip"
      "*.git"
      # keep-sorted end
    ];
  };
in {
  home.packages = [
    inputs.mnemosyne.packages.${system}.default
  ];

  xdg.configFile."mnemosyne/mnemosyne.config.jsonc".source =
    (pkgs.formats.json {}).generate "mnemosyne.config.json" mnemosyneSettings;
}
