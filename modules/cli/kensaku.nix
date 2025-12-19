{...}: {
  programs.kensaku = {
    enable = true;

    settings = {
      accent_color = "cyan";
      user_host = true;
      cpu = true;
      memory = true;
      uptime = true;
      os = true;
      kernel = true;
      disk = true;
      network = true;
      shell = true;
      packages = true;
      wm = true;

      art = {
        max_length = 50;
        max_breadth = 12;
        fractal = "julia_set";
      };
    };
  };
}
