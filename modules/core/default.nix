{pkgs, ...}: {
  imports = [
    ./git.nix
  ];

  home.packages = with pkgs; [
    pkgs.nix-search-tv
  ];
}
