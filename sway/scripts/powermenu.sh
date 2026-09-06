#!/usr/bin/env bash
# Rofi-driven power menu (SUPER+SHIFT+P) — the "control center" of the
# old Quickshell build is gone; this plus swaybar's tray (wifi/bluetooth
# applets) covers the same ground with lighter tools.
set -euo pipefail

# Kept in sync with $lock in sway/config by hand — a plain script has no
# way to read sway's config variables, so this is duplicated rather than
# shared. If you change one, change the other.
LOCK_CMD=(swaylock -f -c 000000 --font "Rubik" --indicator-radius 60 \
    --indicator-thickness 4 --inside-color 18181a --ring-color 3a3a3c \
    --text-color f7f7f8 --key-hl-color ffffff --separator-color 000000 \
    --inside-clear-color 18181a --ring-clear-color f7f7f8)

chosen=$(printf 'Lock\nSleep\nRestart\nShutdown\nCancel' | \
    rofi -dmenu -i -theme ~/.config/rofi/theme.rasi -p "power")

case "$chosen" in
    Lock)     "${LOCK_CMD[@]}" ;;
    Sleep)    systemctl suspend ;;
    Restart)  systemctl reboot ;;
    Shutdown) systemctl poweroff ;;
    *)        exit 0 ;;
esac
