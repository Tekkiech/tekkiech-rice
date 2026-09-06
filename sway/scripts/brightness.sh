#!/usr/bin/env bash
# Adjusts brightness via brightnessctl, then reports the new value to
# wob's pipe.
set -euo pipefail

WOB_SOCK="${XDG_RUNTIME_DIR}/wob.sock"

case "${1:-}" in
    up)   brightnessctl set +5% > /dev/null ;;
    down) brightnessctl set 5%- > /dev/null ;;
    *) echo "usage: brightness.sh up|down" >&2; exit 1 ;;
esac

pct="$(brightnessctl -m | cut -d, -f4 | tr -d '%')"
echo "${pct:-0}" > "$WOB_SOCK"
