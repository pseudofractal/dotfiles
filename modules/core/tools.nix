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
      time = {
        disabled = false;
        format = "[$time]($style) ";
        time_format = "%R";
        style = "dimmed";
      };
    };
  };

  programs.zoxide = {
    enable = true;
    enableFishIntegration = true;
    options = ["--cmd cd"];
  };

  programs.bat.enable = true;

  home.activation.batCache = lib.mkForce (lib.hm.dag.entryAfter ["linkGeneration"] ''
    if [ ! -f "${config.xdg.cacheHome}/bat/syntaxes.bin" ]; then
      export XDG_CACHE_HOME=${lib.escapeShellArg config.xdg.cacheHome}
      run ${lib.getExe pkgs.bat} cache --build
    fi
  '');

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
      age
      bitwarden-cli
      rclone
      sops
      uutils-coreutils-noprefix
      # keep-sorted end
    ]
    ++ lib.optionals (!isAndroid) [
      pkgs.wayfreeze
      pkgs.wl-mirror
      pkgs.wlr-randr
    ];
}
