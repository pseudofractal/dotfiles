{
  lib,
  pkgs,
  ...
}: let
  orientationWatcher = pkgs.writeShellApplication {
    name = "niri-auto-rotate";
    runtimeInputs = with pkgs; [
      coreutils
      iio-sensor-proxy
      wlr-randr
    ];
    text = builtins.readFile ./scripts/auto-rotate.sh;
  };
in {
  systemd.user.services.niri-auto-rotate = {
    Unit = {
      Description = "Rotate eDP-1 from accelerometer orientation";
      PartOf = ["graphical-session.target"];
      After = ["graphical-session.target"];
    };
    Service = {
      Type = "simple";
      ExecStart = lib.getExe orientationWatcher;
      Restart = "always";
      RestartSec = 5;
    };
    Install.WantedBy = ["graphical-session.target"];
  };
}
