#!/usr/bin/env bash
# Background loop, launched via exec in sway/config: notifies once when
# the battery drops below a threshold while discharging, instead of
# staring you in the face every poll like a naive "if low, notify"
# loop would (that fires every 30s once you're under the line — this
# only fires once per discharge, resetting when you plug in or charge
# back up past the threshold). Pattern from Omarchy's
# omarchy-battery-low (bin/ in omacom/omarchy), reimplemented without
# its hook system and using sysfs directly rather than upower, matching
# the rest of this rice's "no daemon for one fact" approach.
#
# UNTESTED — this VM has no battery at all, so the discharge branch has
# never actually fired. Logic reviewed by eye, not run.
set -euo pipefail

THRESHOLD=15
notified=false

battery_status() {
    for bat in /sys/class/power_supply/BAT*; do
        [ -d "$bat" ] || continue
        pct="$(cat "$bat/capacity" 2>/dev/null || echo "")"
        state="$(cat "$bat/status" 2>/dev/null || echo "")"
        [ -n "$pct" ] && echo "$pct $state" && return
    done
}

while true; do
    read -r pct state <<< "$(battery_status)"

    if [ -n "${pct:-}" ]; then
        if [ "$state" = "Discharging" ] && [ "$pct" -le "$THRESHOLD" ]; then
            if [ "$notified" = false ]; then
                notify-send -u critical -i battery-caution -t 30000 \
                    "Time to recharge!" "Battery is down to ${pct}%"
                notified=true
            fi
        else
            notified=false
        fi
    fi

    sleep 60
done
