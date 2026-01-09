{pkgs, ...}: {
  home.packages = with pkgs; [
    mesa-demos
  ];
  useNixGL = true;
}
