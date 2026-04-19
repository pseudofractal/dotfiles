{pkgs, ...}: {
  home.packages = with pkgs; [
    iproute2
  ];

  dotfiles.graphical.nixgl.requests.home = [
    {
      package = pkgs.mesa-demos;
      bin = "glxinfo";
    }
  ];
}
