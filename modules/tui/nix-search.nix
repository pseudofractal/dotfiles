{pkgs, ...}: let
  scriptSource = pkgs.fetchurl {
    url = "https://raw.githubusercontent.com/3timeslazy/nix-search-tv/main/nixpkgs.sh";
    hash = "sha256-+E1vHvWZzYqhlDB1e646kVVopmlMmOX/OFvcCOAHLow=";
  };

  nix-search = pkgs.writeShellScriptBin "nix-search" (builtins.readFile scriptSource);
in {
  home.packages = [
    pkgs.nix-search-tv
    pkgs.fzf
    nix-search
  ];
}
