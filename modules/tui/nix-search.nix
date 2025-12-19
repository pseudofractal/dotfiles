{pkgs, ...}: let
  scriptSource = pkgs.fetchurl {
    url = "https://raw.githubusercontent.com/3timeslazy/nix-search-tv/main/nixpkgs.sh";
    hash = "sha256-XkBL7EdPIETdi8B5k0ww3d66xB7QnW+mFEK2RUihWcY=";
  };

  nix-search = pkgs.writeShellScriptBin "nix-search" (builtins.readFile scriptSource);
in {
  home.packages = [
    pkgs.nix-search-tv
    pkgs.fzf
    nix-search
  ];
}
