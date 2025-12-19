{
  description = "My Dotfiles";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    nix-std.url = "github:chessai/nix-std";

    # For secrets
    sops-nix.url = "github:Mic92/sops-nix";
    sops-nix.inputs.nixpkgs.follows = "nixpkgs";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    catppuccin.url = "github:catppuccin/nix";

    # My custom packages and configurations
    kensaku.url = "github:pseudofractal/kensaku";
    kensaku.inputs.nixpkgs.follows = "nixpkgs";

    mnemosyne.url = "github:pseudofractal/mnemosyne";
    mnemosyne.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = {
    self,
    nixpkgs,
    home-manager,
    nix-std,
    sops-nix,
    catppuccin,
    kensaku,
    mnemosyne,
    ...
  } @ inputs: let
    system = "x86_64-linux";
    pkgs = nixpkgs.legacyPackages.${system};
    std = nix-std.lib;
  in {
    homeConfigurations = {
      "pseudofractal" = home-manager.lib.homeManagerConfiguration {
        inherit pkgs;
        extraSpecialArgs = {
          inherit inputs;
        };
        modules = [
          sops-nix.homeManagerModules.sops

          ./hosts/arch/default.nix
          catppuccin.homeModules.catppuccin

          inputs.mnemosyne.homeManagerModules.default
          kensaku.homeManagerModules.default
        ];
      };
    };
  };
}
