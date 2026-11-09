{pkgs, ...}: let
  # The GNOME ScreenCast dialog is centered on the 1920x1200 output; its Share
  # button is at (1240, 391). dotool takes fractions of the output size.
  shareButtonX = 0.645833;
  shareButtonY = 0.325833;

  watcher = pkgs.writeShellScript "nectarlink-share-pointer" ''
    set -eu

    # NectarLink calls SelectSources with this handle token immediately before
    # the portal dialog opens. Read busctl through a FIFO so grep can stop
    # after the first match and the monitor can be killed cleanly.
    tmpdir="$(mktemp -d "''${XDG_RUNTIME_DIR:-/tmp}/nectarlink-share-pointer.XXXXXX")"
    trap 'rm -rf "$tmpdir"' EXIT
    fifo="$tmpdir/events"
    mkfifo "$fifo"

    /usr/bin/busctl monitor --user \
      --match "type='method_call',interface='org.freedesktop.portal.ScreenCast',member='SelectSources'" \
      --json=short >"$fifo" &
    monitor_pid=$!

    /usr/bin/grep --line-buffered -m1 "nectarlink_sc_req2_" "$fifo" >/dev/null
    kill "$monitor_pid" 2>/dev/null || true
    wait "$monitor_pid" 2>/dev/null || true

    sleep 0.5
    printf 'mouseto ${toString shareButtonX} ${toString shareButtonY}\n' |
      ${pkgs.dotool}/bin/dotool
  '';
in {
  systemd.user.services.nectarlink-share-pointer = {
    Unit = {
      Description = "Move the pointer to NectarLink's portal Share button";
      After = ["graphical-session.target"];
      PartOf = ["graphical-session.target"];
    };
    Service = {
      ExecStart = "${watcher}";
      Restart = "always";
      RestartSec = 2;
      Nice = 19;
      IOSchedulingClass = "idle";
      MemoryMax = "32M";
      CPUQuota = "5%";
      StandardOutput = "null";
    };
    Install.WantedBy = ["graphical-session.target"];
  };
}
