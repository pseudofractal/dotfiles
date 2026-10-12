#!/usr/bin/env bash
set -euo pipefail

output="eDP-1"
last=""

stdbuf -oL -eL monitor-sensor | while IFS= read -r line; do
  case "$line" in
  *"orientation changed:"*)
    orientation="${line##*: }"
    case "$orientation" in
    normal) transform="normal" ;;
    bottom-up) transform="180" ;;
    left-up) transform="90" ;;
    right-up) transform="270" ;;
    *) continue ;;
    esac
    if [ "$transform" != "$last" ]; then
      wlr-randr --output "$output" --transform "$transform"
      last="$transform"
    fi
    ;;
  esac
done
