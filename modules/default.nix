{ pkgs, ... }: {
  imports = [
    ./core
    ./cli
    ./tui
  ];
}
