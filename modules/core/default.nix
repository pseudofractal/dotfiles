{pkgs, ...}: {
  imports = [
    ./git.nix
    ./nix-search.nix
  ];

  home.packages = with pkgs; [
  ];
}
