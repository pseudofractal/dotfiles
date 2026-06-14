{
  pkgs,
  lib,
  hostname,
  ...
}: {
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

    shellAliases =
      {
        cat = "bat";
        fzf = "fzf --preview 'bat --color=always --style=header,grid --line-range :500 {}'";
        c = "nvim .";
      }
      // (lib.optionalAttrs (hostname == "arch") {
        paru = "env -i HOME=$HOME TERM=$TERM PATH=/usr/local/bin:/usr/bin:/bin paru";
      });
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
