{pkgs, ...}: let
  scriptSource = pkgs.fetchurl {
    url = "https://raw.githubusercontent.com/3timeslazy/nix-search-tv/main/nixpkgs.sh";
    hash = "sha256-UHrXo6tlXABheZ6Nkvpe0by2mkKUAgYGTYQpGwj9dpk=";
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
