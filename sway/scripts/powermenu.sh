#!/usr/bin/env bash
# Rofi-driven power menu (SUPER+SHIFT+P) — the "control center" of the
# old Quickshell build is gone; this plus swaybar's tray (wifi/bluetooth
# applets) covers the same ground with lighter tools.
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

chosen=$(printf 'Lock\nSleep\nRestart\nShutdown\nCancel' | \
    rofi -dmenu -i -theme ~/.config/rofi/theme.rasi -p "power")

case "$chosen" in
    Lock)     "$DIR/lock.sh" ;;
    Sleep)    systemctl suspend ;;
    Restart)  systemctl reboot ;;
    Shutdown) systemctl poweroff ;;
    *)        exit 0 ;;
esac
