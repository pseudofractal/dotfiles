{pkgs, ...}: {
  home.packages = with pkgs; [
    maple-mono.NF-CN
  ];
  fonts.fontconfig.enable = true;
}
