{
  config,
  lib,
  pkgs,
  ...
}: let
  notifySend = lib.getExe' pkgs.libnotify "notify-send";

  watcher = pkgs.writeShellScript "battery-watch" ''
    set -u
    warnLevels="8 9 10"
    criticalFrom=9
    hibernateAt=8
    rearmMargin=2
    pollInterval=45
    retryDelay=60
    noAnswerGrace=60
    notifyTimeoutMs=120000
    BAT=/sys/class/power_supply/BAT0
    STATE="''${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/battery-watch"
    mkdir -p "$STATE"

    while true; do
      if [ ! -r "$BAT/capacity" ]; then
        sleep "$retryDelay"
        continue
      fi
      cap=$(cat "$BAT/capacity")
      status=$(cat "$BAT/status" 2>/dev/null || echo Unknown)

      if [ "$status" != "Discharging" ]; then
        rm -f "$STATE"/prompted-*
        sleep "$retryDelay"
        continue
      fi

      for warnLevel in $warnLevels; do
        if [ "$cap" -gt $((warnLevel + rearmMargin)) ]; then
          rm -f "$STATE/prompted-$warnLevel"
        fi
      done

      level=""
      for warnLevel in $warnLevels; do
        if [ "$cap" -le "$warnLevel" ] && [ ! -f "$STATE/prompted-$warnLevel" ]; then
          level=$warnLevel
          break
        fi
      done

      if [ -n "$level" ]; then
        touch "$STATE/prompted-$level"
        urgency=normal
        [ "$level" -le "$criticalFrom" ] && urgency=critical
        choice=$(${notifySend} -u "$urgency" -t "$notifyTimeoutMs" \
          -A hibernate="Hibernate now" \
          -A suspend="Suspend" \
          -A dismiss="Dismiss" \
          "Battery ''${cap}% — unplugged" \
          "Hibernate saves your Niri session to disk. Suspend keeps it in RAM.")
        case "$choice" in
          hibernate) /usr/bin/systemctl hibernate ;;
          suspend) /usr/bin/systemctl suspend ;;
        esac
        if [ "$level" = "$hibernateAt" ] && [ -z "$choice" ]; then
          sleep "$noAnswerGrace"
          stillCapped=$(cat "$BAT/capacity" 2>/dev/null || echo 100)
          stillStatus=$(cat "$BAT/status" 2>/dev/null || echo Unknown)
          if [ "$stillStatus" = "Discharging" ] && [ "$stillCapped" -le "$hibernateAt" ]; then
            /usr/bin/systemctl hibernate
          fi
        fi
      fi
      sleep "$pollInterval"
    done
  '';
in {
  systemd.user.services.battery-watch = {
    Unit = {
      Description = "Interactive low-battery prompts with hibernate fallback";
      PartOf = ["graphical-session.target"];
      After = ["graphical-session.target"];
    };
    Service = {
      Type = "simple";
      ExecStart = watcher;
      Restart = "on-failure";
      RestartSec = 30;
    };
    Install.WantedBy = ["graphical-session.target"];
  };
}
