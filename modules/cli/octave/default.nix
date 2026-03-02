{config, pkgs, ...}: let
  octaveWithPackages = pkgs.octave.withPackages (ps: [
    ps.io
    ps.dataframe
    ps.statistics
    ps.signal
    ps.image
  ]);
in {
  home.packages = with pkgs; [
    octaveWithPackages
    gnuplot
  ];

  xdg.configFile = {
    "octave/site/astro_constants.m".source = ./astro_constants.m;
    "octave/site/astro_units.m".source = ./astro_units.m;
  };

  home.file.".octaverc".text = ''
    addpath("${config.xdg.configHome}/octave/site")
    try
      pkg load io
      pkg load dataframe
      pkg load statistics
      pkg load signal
      pkg load image
    catch
    end

    try
      c = astro_constants();
      u = astro_units();
    catch
    end
  '';
}
