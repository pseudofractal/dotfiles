{
  config,
  lib,
  pkgs,
  inputs,
  ...
}: {
  system.stateVersion = "24.05";

  environment.packages = with pkgs; [
    git
    neovim
    sops
    openssh
    fish
  ];

  android-integration = {
    am.enable = true;
    termux-open.enable = true;
    termux-open-url.enable = true;
    termux-reload-settings.enable = true;
    termux-setup-storage.enable = true;
    termux-wake-lock.enable = true;
    termux-wake-unlock.enable = true;
    xdg-open.enable = true;
  };

  user.shell = "${pkgs.fish}/bin/fish";

  # Backup etc files
  environment.etcBackupExtension = ".bak";

  home-manager.useGlobalPkgs = true;
  home-manager.useUserPackages = true;

  home-manager.config = {pkgs, ...}: {
    imports = [
      ../../modules
      inputs.sops-nix.homeManagerModules.sops
      inputs.catppuccin.homeModules.catppuccin
      inputs.mnemosyne.homeManagerModules.default
      inputs.kensaku.homeManagerModules.default
    ];

    # Configure Sops-Nix for Android
    # We must hardcode the path because $HOME isn't available during activation in the same way
    sops.age.keyFile = "/data/data/com.termux.nix/files/home/.config/sops/age/keys.txt";
    sops.defaultSopsFile = ../../secrets.yaml;

    home.stateVersion = "24.05";
    # CRITICAL: Nix-on-Droid uses this path, not /home/username
    home.homeDirectory = "/data/data/com.termux.nix/files/home";
    home.username = "nix-on-droid";
  };
}
