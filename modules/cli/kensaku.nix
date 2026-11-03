{
  pkgs,
  inputs,
  ...
}: let
  system = pkgs.stdenv.hostPlatform.system;
  kensakuSettings = {
    accent_color = "cyan";
    user_host = true;
    host_model = true;
    os = true;
    kernel = true;
    cpu = true;
    memory = true;
    uptime = true;
    shell = true;
    ip = true;
    packages = true;
    wm = true;
    art = {
      max_length = 50;
      max_breadth = 13;
      fractal = "julia";
      julia.c = {
        one_of = [
          [0.0618524792 0.6176740910]
          [0.0618524792 (-0.6176740910)]
          [(-0.0421060237) 0.6434789089]
          [(-0.0421060237) (-0.6434789089)]
          [(-0.1534603579) 0.6488193447]
          [(-0.1534603579) (-0.6488193447)]
          [(-0.2671298224) 0.6320242149]
          [(-0.2671298224) (-0.6320242149)]
          [(-0.3806705000) 0.5915500779]
          [(-0.3806705000) (-0.5915500779)]
          [(-0.4848362218) 0.5294096172]
          [(-0.4848362218) (-0.5294096172)]
          [(-0.5777798991) 0.4458423784]
          [(-0.5777798991) (-0.4458423784)]
          [(-0.6538790926) 0.3443317270]
          [(-0.6538790926) (-0.3443317270)]
          [(-0.7105988011) 0.2256633547]
          [(-0.7105988011) (-0.2256633547)]
        ];
      };
    };
  };
in {
  home.packages = [
    inputs.kensaku.packages.${system}.default
  ];

  xdg.configFile."kensaku/config.toml".source =
    (pkgs.formats.toml {}).generate "kensaku-config.toml" kensakuSettings;
}
