{pkgs, ...}: {
  home.packages = with pkgs; [
    packet
  ];
}
