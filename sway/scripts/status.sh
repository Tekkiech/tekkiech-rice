#!/usr/bin/env bash
# swaybar status_command — i3bar JSON protocol (man i3bar-protocol).
# Deliberately a plain poll loop, no i3blocks/i3status dependency: one
# fewer package, full control over formatting.
#
# Workspaces are drawn by swaybar itself; this only produces the
# right-aligned block row (window title, mic, bluetooth, wifi, volume,
# power profile, battery, clock) — i3bar's protocol has no "center" and
# no way to put blocks between the workspace buttons and here, that's
# the tradeoff for not running waybar.

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

TEXT="#f7f7f8"
DIM="#b3b3b8"
FAINT="#7a7a80"

block() { # name, full_text, color
    printf '{"name":"%s","full_text":"%s","color":"%s","separator_block_width":18}' \
        "$1" "$(echo -n "$2" | sed 's/"/\\"/g')" "$3"
}

# Every external call here is timeout-guarded: this loop is sequential,
# so any one of these hanging (bluetoothctl does, on a machine with no
# adapter at all — bluetooth.service just sits there with nothing to
# answer it — found live on the test VM) would freeze the entire bar,
# not just that one block.

window_title() {
    # `select(.focused == true)` alone also matches the focused empty
    # workspace container when no window is open (its .name is just the
    # workspace number, e.g. "1") — found live: the bar showed a bare "1"
    # with nothing running. Requiring .pid restricts this to an actual
    # window, since workspace/output/split containers don't have one.
    timeout 2 swaymsg -t get_tree 2>/dev/null | \
        timeout 2 jq -r '.. | objects | select(.focused == true and .pid != null) | .name // empty' 2>/dev/null | \
        head -1 | cut -c1-60
}

mic_muted() {
    timeout 2 wpctl get-volume @DEFAULT_AUDIO_SOURCE@ 2>/dev/null | grep -q MUTED && echo 1 || echo 0
}

bluetooth_on() {
    timeout 2 bluetoothctl show 2>/dev/null | grep -q "Powered: yes" && echo 1 || echo 0
}

wifi_ssid() {
    timeout 2 nmcli -t -f active,ssid dev wifi 2>/dev/null | awk -F: '$1=="yes"{print $2; exit}'
}

volume_pct() {
    # wpctl reports a 0.00-1.00+ fraction ("Volume: 1.00" = 100%), not a
    # percentage — found live: this used to grab just the digit before
    # the decimal point, so 100% showed as "1%". Needs the full fraction
    # times 100, not a substring of it.
    local raw
    raw="$(timeout 2 wpctl get-volume @DEFAULT_AUDIO_SINK@ 2>/dev/null | grep -oP '(?<=Volume: )[\d.]+')"
    [ -n "$raw" ] && awk -v v="$raw" 'BEGIN { printf "%d", v * 100 }'
}

power_profile() {
    timeout 2 "$DIR/powerprofile.sh" current 2>/dev/null
}

battery_pct() {
    for bat in /sys/class/power_supply/BAT*; do
        [ -d "$bat" ] && cat "$bat/capacity" 2>/dev/null && return
    done
}

echo '{"version":1,"click_events":false}'
echo '['
echo '[],'

while true; do
    blocks=()

    title="$(window_title)"
    [ -n "$title" ] && blocks+=("$(block title "$title" "$DIM")")

    [ "$(mic_muted)" = "1" ] && blocks+=("$(block mic "mic muted" "$FAINT")")

    [ "$(bluetooth_on)" = "1" ] && blocks+=("$(block bt "bt" "$DIM")")

    ssid="$(wifi_ssid)"
    [ -n "$ssid" ] && blocks+=("$(block wifi "$ssid" "$DIM")")

    vol="$(volume_pct)"
    [ -n "$vol" ] && blocks+=("$(block vol "vol ${vol}%" "$DIM")")

    profile="$(power_profile)"
    [ -n "$profile" ] && blocks+=("$(block powerprofile "$profile" "$FAINT")")

    bat="$(battery_pct)"
    [ -n "$bat" ] && blocks+=("$(block battery "${bat}%" "$DIM")")

    blocks+=("$(block clock "$(date '+%H:%M    %a, %b %-d')" "$TEXT")")

    joined=$(IFS=,; echo "${blocks[*]}")
    echo "[${joined}],"

    sleep 2
done
