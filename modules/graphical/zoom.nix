{pkgs, ...}: {
  home.packages = with pkgs; [
    zoom-us
  ];
  useNixGL = true;
}
