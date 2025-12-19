{pkgs, ...}: {
  imports = [
    ./core
    ./cli
    ./tui
    ./programming
  ];
}
