#!/usr/bin/env bash
set -euo pipefail

freeze_pid=

unfreeze_screen() {
  if [[ -n "$freeze_pid" ]]; then
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
  [[ -n "$geometry" ]] || return 1
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

handle_gitmoji() {
  local gitmoji_file selected selected_code selected_emoji
  gitmoji_file="${XDG_CONFIG_HOME:-$HOME/.config}/niri/gitmojis.json"
  selected="$(jq -r '.[] | .emoji + "  " + .code + " - " + .description' "$gitmoji_file" | wofi -dmenu -i)"

  [[ -n "$selected" ]] || return 0
  selected_code="$(printf '%s\n' "$selected" | awk -F' - ' '{print $1}' | awk '{print $NF}')"
  selected_emoji="$(jq -r --arg code "$selected_code" '.[] | select(.code == $code) | .emoji' "$gitmoji_file")"

  if [[ -n "$selected_emoji" ]]; then
    printf '%s' "$selected_emoji" | wl-copy
    notify-send "Gitmoji Copied" "Gitmoji copied to clipboard: $selected_emoji (Code: $selected_code)"
  else
    notify-send "Error" "Could not extract emoji for code '$selected_code'."
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
handle_gitmoji)
  handle_gitmoji
  ;;
*)
  printf 'usage: %s {screenshot|screenshot_with_file|handle_gitmoji}\n' "$0" >&2
  exit 2
  ;;
esac
