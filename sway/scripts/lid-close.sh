#!/usr/bin/env bash
# Lid switch handler — bound to `bindswitch lid:on/off` in sway/config.
# Logic adapted from Omarchy's omarchy-system-lid-close /
# omarchy-hw-clamshell (bin/ in omacom/omarchy): lock on lid-close, but
# only if there's no external monitor — a docked laptop with the lid
# shut ("clamshell mode") should keep running on the external display,
# not lock or blank it. Reads /proc/acpi/button/lid directly rather
# than a daemon, same "no extra service for one fact" reasoning as
# status.sh reading /sys/class/power_supply directly for battery.
#
# UNTESTED beyond `bash -n` — this VM has no lid switch or real display
# outputs to exercise the clamshell branch against. Needs a real laptop.
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

lid_closed() {
    for state in /proc/acpi/button/lid/*/state; do
        [ -r "$state" ] || continue
        grep -q closed "$state" && return 0
    done
    return 1
}

# Active outputs whose name doesn't look like a built-in panel
# (eDP-*/LVDS-*) count as "external monitor present".
external_monitor_connected() {
    swaymsg -t get_outputs 2>/dev/null | \
        jq -e '[.[] | select(.active == true and (.name | test("^(eDP|LVDS)") | not))] | length > 0' \
        >/dev/null 2>&1
}

internal_output() {
    swaymsg -t get_outputs 2>/dev/null | \
        jq -r '.[] | select(.name | test("^(eDP|LVDS)")) | .name' | head -1
}

if lid_closed && ! external_monitor_connected; then
    "$DIR/lock.sh" &
fi

# Always reconcile the internal panel's power state, independent of
# whether we just locked — covers lid-open too (bound separately).
output="$(internal_output)"
if [ -n "$output" ]; then
    if lid_closed && external_monitor_connected; then
        swaymsg output "$output" disable >/dev/null 2>&1 || true
    else
        swaymsg output "$output" enable >/dev/null 2>&1 || true
    fi
fi
