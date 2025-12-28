{pkgs, ...}: {
  system.stateVersion = "24.05";

  environment.packages = with pkgs; [
    git
    openssh
    fish
    sops
    vim
    coreutils
    ncurses
    procps
    findutils
  ];

  android-integration = {
    am.enable = true; # Android Activity Manager
    termux-open.enable = true; # Open files in Android apps
    termux-open-url.enable = true; # Open URLs in Android browser
    termux-reload-settings.enable = true; # Reload Termux styling
    termux-setup-storage.enable = true; # Access /sdcard/ storage
    termux-wake-lock.enable = true; # Prevent phone from sleeping during builds
    termux-wake-unlock.enable = true; # Release wake lock
    xdg-open.enable = true; # Standard Linux `open` command mapping
  };

  user.shell = "${pkgs.fish}/bin/fish";

  environment.etcBackupExtension = ".bak";
}
