{
  description = "My Dotfiles";

  nixConfig = {
    extra-substituters = [
      "https://noctalia.cachix.org"
      "https://vicinae.cachix.org"
    ];
    extra-trusted-public-keys = [
      "noctalia.cachix.org-1:pCOR47nnMEo5thcxNDtzWpOxNFQsBRglJzxWPp3dkU4="
      "vicinae.cachix.org-1:1kDrfienkGHPYbkpNj1mWTr7Fm1+zcenzgTizIcI3oc="
    ];
  };

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
    nixgl.url = "github:nix-community/nixGL";
    lmstudio = {
      url = "github:Daaboulex/lmstudio-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    zen-browser = {
      url = "github:0xc000022070/zen-browser-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nur-vortriz = {
      url = "github:Vortriz/nur-packages";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    firefox-addons = {
      url = "gitlab:rycee/nur-expressions?dir=pkgs/firefox-addons";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    opencode = {
      url = "github:anomalyco/opencode";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    noctalia = {
      url = "github:noctalia-dev/noctalia/cachix";
    };
    nvf = {
      url = "github:notashelf/nvf";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # My Personal Modules
    kensaku.url = "github:pseudofractal/kensaku";
    rmcl.url = "github:pseudofractal/rmcl";
    mnemosyne.url = "github:pseudofractal/mnemosyne";
    shiryoku.url = "github:pseudofractal/shiryoku";

    vicinae = {
      url = "github:vicinaehq/vicinae";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    vicinae-extensions = {
      url = "github:vicinaehq/extensions";
      flake = false;
    };
  };

  outputs = {
    self,
    nixpkgs,
    home-manager,
    nix-on-droid,
    treefmt-nix,
    ...
  } @ inputs: let
    system = "x86_64-linux";
    pkgs = import nixpkgs {inherit system;};
    treefmtEval = treefmt-nix.lib.evalModule pkgs ./treefmt.nix;
    # Builder for Standalone Home Manager
    mkHome = {
      hostname,
      pkgsInput ? nixpkgs,
    }:
      home-manager.lib.homeManagerConfiguration {
        pkgs = import pkgsInput {
          inherit system;
          config.allowUnfree = true;
        };
        extraSpecialArgs = {
          inherit inputs hostname;
          isAndroid = false;
          isNixOS = false;
        };
        modules = [
          ./hosts/${hostname}/default.nix
        ];
      };

    # Builder for Nix-on-Droid
    mkDroid = {
      hostname,
      pkgsInput ? nixpkgs,
    }: let
      system = "aarch64-linux";
    in
      nix-on-droid.lib.nixOnDroidConfiguration {
        pkgs = import pkgsInput {
          inherit system;
          config.allowUnfree = true;
        };
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
              inherit inputs hostname system;
              isAndroid = true;
              isNixOS = false;
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

    formatter.${system} = treefmtEval.config.build.wrapper;

    checks.${system}.formatting = treefmtEval.config.build.check self;
  };
}
