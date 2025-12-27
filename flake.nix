{
  description = "My Dotfiles";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    nix-std.url = "github:chessai/nix-std";

    # For secrets
    sops-nix.url = "github:Mic92/sops-nix";
    sops-nix.inputs.nixpkgs.follows = "nixpkgs";

    nix-on-droid = {
      url = "github:nix-community/nix-on-droid";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.home-manager.follows = "home-manager";
    };

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    catppuccin.url = "github:catppuccin/nix";

    nur = {
      url = "github:nix-community/NUR";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # My custom packages and configurations
    kensaku.url = "github:pseudofractal/kensaku";
    kensaku.inputs.nixpkgs.follows = "nixpkgs";

    mnemosyne.url = "github:pseudofractal/mnemosyne";
    mnemosyne.inputs.nixpkgs.follows = "nixpkgs";

    shiryoku.url = "github:pseudofractal/shiryoku";
    shiryoku.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = {
    nixpkgs,
    nix-on-droid,
    home-manager,
    ...
  } @ inputs: let
    system = "x86_64-linux";
    pkgs = nixpkgs.legacyPackages.${system};
  in {
    homeConfigurations = {
      "pseudofractal" = home-manager.lib.homeManagerConfiguration {
        inherit pkgs;
        extraSpecialArgs = {
          inherit inputs;
          hostname = "arch";
        };
        modules = [
          inputs.sops-nix.homeManagerModules.sops

          ./hosts/arch/default.nix
          inputs.catppuccin.homeModules.catppuccin

          inputs.mnemosyne.homeManagerModules.default
          inputs.kensaku.homeManagerModules.default
          inputs.shiryoku.homeManagerModules.default
        ];
      };
    };
    nixOnDroidConfigurations = {
      "koch" = nix-on-droid.lib.nixOnDroidConfiguration {
        pkgs = import nixpkgs {system = "aarch64-linux";};
        extraSpecialArgs = {
          inherit inputs;
          hostname = "koch";
        };
        modules = [
          ./hosts/android/default.nix
        ];
      };
    };
  };
}
