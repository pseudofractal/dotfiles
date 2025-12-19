{pkgs, ...}: {
  programs.fish = {
    enable = true;

    interactiveShellInit = ''
      set fish_greeting # Disable greeting
      kensaku
    '';

    plugins = [
      {
        name = "bass";
        src = pkgs.fishPlugins.bass.src;
      }
    ];

    shellAbbrs = {
      gc = "git commit -m";
      gaa = "git add -A";
      gp = "git push";
      nv = "nvim .";
    };

    shellAliases = {
      cat = "bat";
      fzf = "fzf --preview 'bat --color=always --style=header,grid --line-range :500 {}'";
      c = "nvim .";
    };


  };

  xdg.configFile."fish/conf.d" = {
    source = ./conf.d;
    recursive = true;
  };

  xdg.configFile."fish/functions" = {
    source = ./functions;
    recursive = true;
  };
}
