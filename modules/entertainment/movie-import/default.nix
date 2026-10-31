{
  config,
  lib,
  pkgs,
  ...
}: let
  downloads = config.xdg.userDirs.download;
  movies = "${config.home.homeDirectory}/Movies";
  importer = pkgs.writeShellApplication {
    name = "movie-import";
    text = ''
      exec ${lib.getExe pkgs.python3} ${./importer.py} ${lib.escapeShellArg downloads} ${lib.escapeShellArg movies}
    '';
  };
in {
  systemd.user.services.movie-import = {
    Unit.Description = "Import completed movie downloads";
    Service = {
      Type = "oneshot";
      ExecStart = lib.getExe importer;
      Nice = 15;
      IOSchedulingClass = "idle";
    };
  };

  systemd.user.paths.movie-import = {
    Unit.Description = "Watch Downloads for movie releases";
    Path = {
      PathChanged = downloads;
      Unit = "movie-import.service";
    };
    Install.WantedBy = ["default.target"];
  };

  systemd.user.timers.movie-import = {
    Unit.Description = "Retry unfinished movie downloads";
    Timer = {
      OnBootSec = "2min";
      OnUnitActiveSec = "5min";
      AccuracySec = "30s";
    };
    Install.WantedBy = ["timers.target"];
  };
}
