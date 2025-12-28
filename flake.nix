{
  description = "My Dotfiles";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";

    nix-on-droid = {
      url = "github:nix-community/nix-on-droid";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.home-manager.follows = "home-manager";
    };
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nur = {
      url = "github:nix-community/NUR";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # External Module Sources
    catppuccin.url = "github:catppuccin/nix";

    # My Personal Modules
    kensaku.url = "github:pseudofractal/kensaku";
    mnemosyne.url = "github:pseudofractal/mnemosyne";
    shiryoku.url = "github:pseudofractal/shiryoku";
  };

  outputs = {
    nixpkgs,
    home-manager,
    nix-on-droid,
    ...
  } @ inputs: let
    system = "x86_64-linux";
    # Builder for Standalone Home Manager
    mkHome = {
      hostname,
      pkgsInput ? nixpkgs,
    }:
      home-manager.lib.homeManagerConfiguration {
        pkgs = pkgsInput.legacyPackages.${system};
        extraSpecialArgs = {
          inherit inputs hostname;
          isAndroid = false;
          isLinux = true;
        };
        modules = [
          ./hosts/${hostname}/default.nix
        ];
      };

    # Builder for Nix-on-Droid
    mkDroid = {
      hostname,
      pkgsInput ? nixpkgs,
    }:
      nix-on-droid.lib.nixOnDroidConfiguration {
        pkgs = import pkgsInput {system = "aarch64-linux";};
        extraSpecialArgs = {inherit inputs hostname;};
        modules = [
          # Hardware
          ./hosts/android/system.nix
          {
            # Home Manager
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.backupFileExtension = "hm-bak";
            home-manager.extraSpecialArgs = {
              inherit inputs hostname;
              isAndroid = true;
              isLinux = false;
            };
            home-manager.config = ./hosts/android/home.nix;
          }
        ];
      };
  in {
    homeConfigurations."pseudofractal" = mkHome {
      hostname = "arch";
    };

    nixOnDroidConfigurations."koch" = mkDroid {
      hostname = "android";
    };
  };
}
