{pkgs, ...}: {
  imports = [
    ./nvim
    ./opencode
                # ./nvf
  ];
  home.packages = with pkgs; [
    numbat
  ];
}
