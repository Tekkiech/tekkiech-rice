#!/usr/bin/env bash
# fuzzel-driven power menu (SUPER+SHIFT+P) — the "control center" of the
# old Quickshell build is gone; this plus swaybar's tray (wifi/bluetooth
# applets) covers the same ground with lighter tools.
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

chosen=$(printf 'Lock\nSleep\nRestart\nShutdown\nCancel' | \
    fuzzel --dmenu -p "power> ")

case "$chosen" in
    Lock)     "$DIR/lock.sh" ;;
    Sleep)    systemctl suspend ;;
    Restart)  systemctl reboot ;;
    Shutdown) systemctl poweroff ;;
    *)        exit 0 ;;
esac
