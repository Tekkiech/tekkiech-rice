#!/usr/bin/env bash
# Keyboard backlight (separate from screen brightness/brightness.sh) —
# most laptops don't have one, so this looks for a device in
# brightnessctl's "leds" class matching *kbd_backlight* (covers the
# common asus::/dell::/smc:: naming) and quietly does nothing if none
# exists, rather than erroring on hardware that isn't there.
#
# UNTESTED — this VM has no backlight devices of any kind.
set -euo pipefail

device="$(brightnessctl -l -c leds 2>/dev/null | grep -oP "(?<=Device ')[^']*kbd_backlight[^']*" | head -1)"
[ -n "$device" ] || exit 0

WOB_SOCK="${XDG_RUNTIME_DIR}/wob.sock"

case "${1:-}" in
    up)   brightnessctl -d "$device" set +10% > /dev/null ;;
    down) brightnessctl -d "$device" set 10%- > /dev/null ;;
    *) echo "usage: kbd-backlight.sh up|down" >&2; exit 1 ;;
esac

pct="$(brightnessctl -d "$device" -m | cut -d, -f4 | tr -d '%')"
[ -p "$WOB_SOCK" ] && echo "${pct:-0}" > "$WOB_SOCK"
