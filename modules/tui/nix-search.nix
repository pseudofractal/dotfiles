{pkgs, ...}: let
  scriptSource = pkgs.fetchurl {
    url = "https://raw.githubusercontent.com/3timeslazy/nix-search-tv/main/nixpkgs.sh";
    hash = "sha256-Kz1L8S0OCK9i9h79T3ISt9AO23LhT3hZAnNaIyhFYjE=";
  };

  nix-search = pkgs.writeShellScriptBin "nix-search" (builtins.readFile scriptSource);
in {
  home.packages = [
    # keep-sorted start
    nix-search
    pkgs.fzf
    pkgs.nix-search-tv
    # keep-sorted end
  ];
}
