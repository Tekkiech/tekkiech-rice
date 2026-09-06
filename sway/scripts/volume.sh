#!/usr/bin/env bash
# Adjusts volume via wpctl, then reports the new value to wob's pipe.
set -euo pipefail

WOB_SOCK="${XDG_RUNTIME_DIR}/wob.sock"

case "${1:-}" in
    up)   wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+ ;;
    down) wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%- ;;
    mute) wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle ;;
    *) echo "usage: volume.sh up|down|mute" >&2; exit 1 ;;
esac

status="$(wpctl get-volume @DEFAULT_AUDIO_SINK@)"
if echo "$status" | grep -q MUTED; then
    echo 0 > "$WOB_SOCK"
else
    pct="$(echo "$status" | grep -oP '\d+(?=\.\d+)' | head -1)"
    echo "${pct:-0}" > "$WOB_SOCK"
fi
