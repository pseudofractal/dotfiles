#!/usr/bin/env bash
set -euo pipefail

freeze_pid=

unfreeze_screen() {
  if [[ -n $freeze_pid ]]; then
    kill "$freeze_pid" 2>/dev/null || true
    wait "$freeze_pid" 2>/dev/null || true
    freeze_pid=
  fi
}

freeze_screen() {
  wayfreeze &
  freeze_pid=$!
  trap unfreeze_screen EXIT
  sleep 0.1
}

select_geometry() {
  local geometry
  geometry="$(slurp)" || return 1
  [[ -n $geometry ]] || return 1
  printf '%s' "$geometry"
}

take_screenshot() {
  local geometry
  freeze_screen
  geometry="$(select_geometry)" || return 0
  grim -g "$geometry" - | wl-copy --type image/png
  unfreeze_screen
  trap - EXIT
}

take_screenshot_with_file() {
  local directory filename filepath geometry
  directory="${XDG_PICTURES_DIR:-$HOME/Pictures}/Screenshots"
  filename="$(date '+%B %d, %Y %I:%M:%S %p')_screenshot.png"
  filepath="$directory/$filename"
  mkdir -p "$directory"

  freeze_screen
  geometry="$(select_geometry)" || return 0
  grim -g "$geometry" "$filepath"
  unfreeze_screen
  trap - EXIT
  wl-copy --type image/png <"$filepath"
}

toggle_graphics_mode() {
  local current target output
  current="$(supergfxctl --get)"

  case "$current" in
  Integrated) target=Hybrid ;;
  Hybrid) target=Integrated ;;
  *)
    notify-send --urgency=critical "Graphics mode unchanged" \
      "Current mode is $current; only Integrated and Hybrid may be toggled."
    return 1
    ;;
  esac

  if output="$(supergfxctl --mode "$target" 2>&1)"; then
    notify-send "Graphics mode: $target" "${output:-Mode change requested.}"
  else
    notify-send --urgency=critical "Graphics mode change failed" "$output"
    return 1
  fi
}

case "${1:-}" in
screenshot)
  take_screenshot
  ;;
screenshot_with_file)
  take_screenshot_with_file
  ;;
toggle_graphics_mode)
  toggle_graphics_mode
  ;;
*)
  printf 'usage: %s {screenshot|screenshot_with_file|toggle_graphics_mode}\n' "$0" >&2
  exit 2
  ;;
esac
