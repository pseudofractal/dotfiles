{
  inputs,
  pkgs,
  ...
}: {
  home.packages = [
    inputs.ytm-player.packages.${pkgs.stdenv.hostPlatform.system}.default
  ];
}
