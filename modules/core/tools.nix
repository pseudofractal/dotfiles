{pkgs, ...}: {
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
    # For secret management
    sops
    age
  ];
}
