{pkgs, ...}: {
  home.packages = with pkgs; [
    mesa-demos
    iproute2
  ];
  useNixGL = true;
}
