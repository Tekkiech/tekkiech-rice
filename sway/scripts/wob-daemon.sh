#!/usr/bin/env bash
# Sets up wob's input pipe and feeds it into wob itself. volume.sh /
# brightness.sh write a 0-100 number into this pipe to show the popup.
set -euo pipefail

WOB_SOCK="${XDG_RUNTIME_DIR}/wob.sock"
[ -p "$WOB_SOCK" ] || mkfifo "$WOB_SOCK"

tail -f "$WOB_SOCK" | wob -c ~/.config/wob/wob.ini
