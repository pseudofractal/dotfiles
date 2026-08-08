{
  config,
  pkgs,
  lib,
  isAndroid,
  ...
}: {
  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
    enableFishIntegration = true;
  };

  programs.starship = {
    enable = true;
    enableFishIntegration = true;
    settings = {
      "$schema" = "https://starship.rs/config-schema.json";
      gcloud = {
        disabled = true;
      };
    };
  };

  # Zoxide replaces cd
  programs.zoxide = {
    enable = true;
    enableFishIntegration = true;
    options = ["--cmd cd"];
  };

  # Bat replaces cat
  programs.bat.enable = true;

  # Only build bat cache on first run — it auto-generates on first use anyway
  home.activation.batCache = lib.mkForce (lib.hm.dag.entryAfter ["linkGeneration"] ''
    if [ ! -f "${config.xdg.cacheHome}/bat/syntaxes.bin" ]; then
      export XDG_CACHE_HOME=${lib.escapeShellArg config.xdg.cacheHome}
      run ${lib.getExe pkgs.bat} cache --build
    fi
  '');

  # Eza replaces ls
  programs.eza = {
    enable = true;
    enableFishIntegration = true;
    icons = "always";
    git = true;
    extraOptions = ["--group-directories-first" "--header"];
  };

  home.packages = with pkgs;
    [
      # keep-sorted start

      # For secret management
      age
      bitwarden-cli
      # For cloud backups
      rclone
      sops
      # Prefer uutils-provided core commands from the Home Manager profile.
      uutils-coreutils-noprefix
      # keep-sorted end
    ]
    ++ lib.optionals (!isAndroid) [
      pkgs.wl-mirror
    ];
}
