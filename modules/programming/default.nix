{pkgs, ...}: {
  imports = [
    ./nvim
    ./opencode
    ./zed.nix
    # ./nvf
  ];
  home.packages = with pkgs; [
    numbat
  ];
}
