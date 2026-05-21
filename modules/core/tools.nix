{pkgs, ...}: {
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

  # Eza replaces ls
  programs.eza = {
    enable = true;
    enableFishIntegration = true;
    icons = "always";
    git = true;
    extraOptions = ["--group-directories-first" "--header"];
  };

  home.packages = with pkgs; [
    # keep-sorted start
    # For secret management
    age
    sops

    # Prefer uutils-provided core commands from the Home Manager profile.
    uutils-coreutils-noprefix
    # keep-sorted end
  ];
}
