#!/usr/bin/env bash
set -euo pipefail

invert="${1:-false}"
directory="${XDG_PICTURES_DIR:-$HOME/Pictures}/SyncShots"
tmp="$(mktemp --suffix=.png)"
preview=
freeze_pid=

cleanup() {
  if [[ -n $freeze_pid ]]; then
    kill "$freeze_pid" 2>/dev/null || true
    wait "$freeze_pid" 2>/dev/null || true
  fi
  rm -f "$tmp" ${preview:+"$preview"}
}
trap cleanup EXIT

mkdir -p "$directory"
wayfreeze &
freeze_pid=$!
sleep 0.1

geometry="$(slurp)" || exit 0
[[ -n $geometry ]] || exit 0

if [[ $invert == "true" ]]; then
  grim -g "$geometry" - | catppucinify --stdin --invert --scale 2 >"$tmp"
else
  grim -g "$geometry" - | catppucinify --stdin --scale 2 >"$tmp"
fi

# Unfreeze before showing any UI - yad would be hidden behind the wayfreeze overlay
kill "$freeze_pid" 2>/dev/null || true
wait "$freeze_pid" 2>/dev/null || true
freeze_pid=

default="$(date '+%B_%d_%Y__%I-%M-%S_%p')"
if [[ $invert == "true" ]]; then
  default="${default}__inverted"
fi

preview="$(mktemp --suffix=.png)"
magick "$tmp" -auto-orient -thumbnail '420x420>' "$preview"

name="$(yad --entry \
  --width=520 \
  --height=560 \
  --center \
  --on-top \
  --title="Save SyncShot" \
  --text="" \
  --entry-text="$default" \
  --image="$preview" \
  --button="Cancel:1" \
  --button="Save:0")" || exit 0

[[ -n $name ]] || exit 0
file="$directory/${name%.png}.png"
cp "$tmp" "$file"
wl-copy --type image/png <"$file"
