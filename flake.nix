{
  description = "My Dotfiles";

  nixConfig = {
    extra-substituters = [
      "https://niri-nix.cachix.org"
      "https://noctalia.cachix.org"
      "https://vicinae.cachix.org"
    ];
    extra-trusted-public-keys = [
      "niri-nix.cachix.org-1:SvFtqpDcf7Sm1SMJdby1/+Y+6f3Yt3/3PMcSTKPJNJ0="
      "noctalia.cachix.org-1:pCOR47nnMEo5thcxNDtzWpOxNFQsBRglJzxWPp3dkU4="
      "vicinae.cachix.org-1:1kDrfienkGHPYbkpNj1mWTr7Fm1+zcenzgTizIcI3oc="
    ];
  };

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    nixpkgs-llama.url = "github:NixOS/nixpkgs/39ad350a0602fa0a58a544344e3e9187526ea45c";

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

    catppuccin.url = "github:catppuccin/nix";
    nixgl.url = "github:nix-community/nixGL";
    niri-nix = {
      url = "git+https://codeberg.org/BANanaD3V/niri-nix";
    };
    nix-system-graphics = {
      url = "github:soupglasses/nix-system-graphics";
      inputs.nixpkgs.follows = "nixpkgs";
    };
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
    nixpkgs-zotero.url = "github:NixOS/nixpkgs/88c4c23f3d6e5a4116ee19e148df5a0f2004f861";
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
    system-manager = {
      url = "github:numtide/system-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    kensaku.url = "github:pseudofractal/kensaku";
    rmcl.url = "github:pseudofractal/rmcl";
    mnemosyne.url = "github:pseudofractal/mnemosyne";
    shiryoku.url = "github:pseudofractal/shiryoku";

    vicinae = {
      url = "github:vicinaehq/vicinae";
    };
    vicinae-extensions = {
      url = "github:vicinaehq/extensions";
      flake = false;
    };
    vicinae-color-picker = {
      url = "github:psampir/vicinae-color-picker";
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
    mkHome = {
      hostname,
      pkgsInput ? nixpkgs,
    }:
      home-manager.lib.homeManagerConfiguration {
        pkgs = import pkgsInput {
          inherit system;
          config.allowUnfree = true;
          overlays = [inputs.niri-nix.overlays.niri-nix];
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
          ./hosts/android/system.nix
          {
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

    systemConfigs.arch = inputs.system-manager.lib.makeSystemConfig {
      modules = [./hosts/arch/system.nix];
      overlays = [inputs.niri-nix.overlays.niri-nix];
      specialArgs = {inherit inputs;};
    };

    nixOnDroidConfigurations."koch" = mkDroid {
      hostname = "android";
    };

    formatter.${system} = treefmtEval.config.build.wrapper;

    checks.${system}.formatting = treefmtEval.config.build.check self;
  };
}
