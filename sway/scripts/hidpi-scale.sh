#!/usr/bin/env bash
# Auto-scales any HiDPI output. Written for the M1 Pro 14" MacBook's
# internal panel — 3024x1964 native — but keyed off the reported mode
# width rather than a hardcoded connector name, since Asahi's eDP
# connector naming isn't confirmed stable across kernel versions.
#
# Scale-2 for anything >=2560px wide matches Apple's own out-of-box
# default for this exact panel (macOS's "Default" display setting on
# the M1 Pro 14" is a logical 1512x982 over the 3024x1964 native mode,
# i.e. exactly 2x) — not a guessed threshold.
#
# Run via exec_always so it also re-applies after an output change
# (e.g. undocking); harmless no-op on the VM's 1920x1080 virtual output.
set -uo pipefail

THRESHOLD=2560

swaymsg -t get_outputs -r 2>/dev/null | jq -c '.[]' | while read -r output; do
    name="$(jq -r '.name' <<<"$output")"
    scale="$(jq -r '.scale' <<<"$output")"
    width="$(jq -r '.current_mode.width // empty' <<<"$output")"
    [ -z "$width" ] && continue

    if [ "$width" -ge "$THRESHOLD" ]; then
        target=2
    else
        target=1
    fi

    # jq's scale is a float ("1.000000"); compare as integers to avoid
    # re-issuing the same swaymsg command every time this script reruns.
    current="$(awk -v s="$scale" 'BEGIN { printf "%d", s }')"
    if [ "$current" != "$target" ]; then
        swaymsg output "$name" scale "$target" >/dev/null
    fi
done
