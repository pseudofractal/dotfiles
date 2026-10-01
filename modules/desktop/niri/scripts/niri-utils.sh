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

case "${1:-}" in
screenshot)
  take_screenshot
  ;;
screenshot_with_file)
  take_screenshot_with_file
  ;;
*)
  printf 'usage: %s {screenshot|screenshot_with_file}\n' "$0" >&2
  exit 2
  ;;
esac
