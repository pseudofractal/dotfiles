{pkgs, ...}: {
  programs.mnemosyne = {
    enable = true;

    settings = {
      dependency_graph = false;
      ignore = [
        # imaging junk
        "*.png"
        "*.jpg"
        "*.jpeg"
        "*.gif"
        "*.bmp"
        "*.ico"
        "*.svg"
        # video / audio
        "*.mp4"
        "*.avi"
        "*.mov"
        "*.mkv"
        "*.mp3"
        "*.wav"
        "*.ogg"
        # archives & packages
        "*.zip"
        "*.tar"
        "*.gz"
        "*.bz2"
        "*.pack"
        # fonts
        "*.ttf"
        "*.otf"
        "*.woff"
        "*.woff2"
        "*.eot"
        # binaries / libs / objects
        "*.exe"
        "*.dll"
        "*.so"
        "*.a"
        "*.o"
        "*.jar"
        "*.class"
        # astronomy raw + indices
        "*.fits"
        "*.rev"
        "*.idx"
        "*.ctab"
        "*.npy"
        # misc noise
        "*.po"
        "*.git"
      ];
    };
  };
}
