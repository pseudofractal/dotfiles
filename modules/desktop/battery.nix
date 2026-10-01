# Interactive low-battery watcher.
#
# Polls BAT0 while unplugged and asks (notification buttons, no forced
# action) at 10%, 9% and 8%. At 8% with no answer for 3 minutes it
# hibernates anyway to save the Niri session. Each level fires once per
# discharge cycle; markers reset when charging or back above threshold+2.
#
# Note: action buttons need a notification daemon with action support
# (Noctalia provides it). If buttons ever stop appearing, fall back to a
# yad question dialog for the 8% level.
{
  config,
  lib,
  pkgs,
  ...
}: let
  notifySend = lib.getExe' pkgs.libnotify "notify-send";

  watcher = pkgs.writeShellScript "battery-watch" ''
    set -u
    BAT=/sys/class/power_supply/BAT0
    STATE="''${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/battery-watch"
    mkdir -p "$STATE"

    while true; do
      if [ ! -r "$BAT/capacity" ]; then
        sleep 60
        continue
      fi
      cap=$(cat "$BAT/capacity")
      status=$(cat "$BAT/status" 2>/dev/null || echo Unknown)

      if [ "$status" != "Discharging" ]; then
        rm -f "$STATE"/prompted-*
        sleep 60
        continue
      fi

      # Hysteresis: allow re-prompt if charged back up past threshold+2.
      for t in 10 9 8; do
        if [ "$cap" -gt $((t + 2)) ]; then
          rm -f "$STATE/prompted-$t"
        fi
      done

      level=""
      if [ "$cap" -le 8 ] && [ ! -f "$STATE/prompted-8" ]; then
        level=8
      elif [ "$cap" -le 9 ] && [ ! -f "$STATE/prompted-9" ]; then
        level=9
      elif [ "$cap" -le 10 ] && [ ! -f "$STATE/prompted-10" ]; then
        level=10
      fi

      if [ -n "$level" ]; then
        touch "$STATE/prompted-$level"
        urgency=normal
        [ "$level" -le 9 ] && urgency=critical
        choice=$(${notifySend} -u "$urgency" -t 120000 \
          -A hibernate="Hibernate now" \
          -A suspend="Suspend" \
          -A dismiss="Dismiss" \
          "Battery ''${cap}% — unplugged" \
          "Hibernate saves your Niri session to disk. Suspend keeps it in RAM.")
        case "$choice" in
          hibernate) /usr/bin/systemctl hibernate ;;
          suspend) /usr/bin/systemctl suspend ;;
        esac
        if [ "$level" = "8" ] && [ -z "$choice" ]; then
          # The notification waits two minutes; allow one more before hibernating.
          sleep 60
          cap2=$(cat "$BAT/capacity" 2>/dev/null || echo 100)
          status2=$(cat "$BAT/status" 2>/dev/null || echo Unknown)
          if [ "$status2" = "Discharging" ] && [ "$cap2" -le 8 ]; then
            /usr/bin/systemctl hibernate
          fi
        fi
      fi
      sleep 45
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
