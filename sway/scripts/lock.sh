#!/usr/bin/env bash
# The one themed swaylock invocation, called from sway/config's $mod+l
# bind, swayidle's timeout/before-sleep hooks, powermenu.sh, and
# lid-close.sh — previously duplicated across three of those by hand
# (with a comment warning to keep them in sync), which is exactly the
# kind of thing that silently drifts. One script instead.
exec swaylock -f -c 000000 --font "Rubik" --indicator-radius 60 \
    --indicator-thickness 4 --inside-color 18181a --ring-color 3a3a3c \
    --text-color f7f7f8 --key-hl-color ffffff --separator-color 000000 \
    --inside-clear-color 18181a --ring-clear-color f7f7f8
