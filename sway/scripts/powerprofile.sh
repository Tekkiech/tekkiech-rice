#!/usr/bin/env bash
# power-profiles-daemon wrapper — pattern adapted from Omarchy's
# omarchy-powerprofiles-set/-init (bin/ in omacom/omarchy): remembers
# your last-chosen profile separately for AC and battery, so plugging
# in/unplugging restores whichever one you picked for that power
# source, rather than always resetting to one default.
#
# Difference from Omarchy's version: AC-vs-battery is read straight
# from /sys/class/power_supply (matches battery_pct()/wifi_ssid() etc.
# in status.sh — no upower/busctl dependency), not a UPower D-Bus
# property. Same fact, lighter path to it.
#
# Usage:
#   powerprofile.sh cycle              # rotate through available profiles
#   powerprofile.sh set <profile>      # set + remember for current power source
#   powerprofile.sh autodetect         # restore the remembered profile for current power source (run on boot / AC change)
#   powerprofile.sh current            # print the active profile (for status.sh)
set -euo pipefail

STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/tekkiech-rice/powerprofile"

on_ac() {
    for supply in /sys/class/power_supply/*; do
        [ -r "$supply/type" ] || continue
        [ "$(cat "$supply/type" 2>/dev/null)" = "Mains" ] || continue
        [ -r "$supply/online" ] || continue
        [ "$(cat "$supply/online" 2>/dev/null)" = "1" ] && return 0
    done
    return 1
}

power_source() {
    on_ac && echo "ac" || echo "battery"
}

available_profiles() {
    # Top-level profile lines are exactly "* name:" or "  name:" (one
    # marker/two spaces, nothing more); nested detail fields like
    # "    PlatformDriver:" are indented further. Found live: the
    # original pattern here matched ANY amount of leading whitespace,
    # so it also picked up "PlatformDriver" as if it were a profile
    # name, and `cycle` tried to powerprofilesctl set it. Anchoring to
    # exactly 2 leading chars excludes the deeper-indented detail lines
    # without needing to know their field names.
    powerprofilesctl list 2>/dev/null | grep -oP '^(\* |  )\K[\w-]+(?=:)' || true
}

profile_available() {
    available_profiles | grep -qx "$1"
}

set_profile() {
    local profile="$1"
    powerprofilesctl set "$profile"
}

case "${1:-}" in
    current)
        powerprofilesctl get 2>/dev/null || echo ""
        ;;

    cycle)
        mapfile -t profiles < <(available_profiles)
        [ "${#profiles[@]}" -gt 0 ] || exit 0
        current="$(powerprofilesctl get 2>/dev/null || echo "")"
        next="${profiles[0]}"
        for i in "${!profiles[@]}"; do
            if [ "${profiles[$i]}" = "$current" ]; then
                next_i=$(( (i + 1) % ${#profiles[@]} ))
                next="${profiles[$next_i]}"
                break
            fi
        done
        set_profile "$next"
        mkdir -p "$STATE_DIR"
        echo "$next" > "$STATE_DIR/$(power_source)"
        ;;

    set)
        profile="${2:-}"
        [ -n "$profile" ] || { echo "usage: powerprofile.sh set <profile>" >&2; exit 1; }
        profile_available "$profile" || { echo "profile not available: $profile" >&2; exit 1; }
        set_profile "$profile"
        mkdir -p "$STATE_DIR"
        echo "$profile" > "$STATE_DIR/$(power_source)"
        ;;

    autodetect)
        source="$(power_source)"
        state_file="$STATE_DIR/$source"
        if [ -r "$state_file" ] && profile_available "$(cat "$state_file")"; then
            set_profile "$(cat "$state_file")"
        elif [ "$source" = "ac" ] && profile_available performance; then
            set_profile performance
        elif profile_available balanced; then
            set_profile balanced
        fi
        ;;

    *)
        echo "usage: powerprofile.sh cycle|set <profile>|autodetect|current" >&2
        exit 1
        ;;
esac
