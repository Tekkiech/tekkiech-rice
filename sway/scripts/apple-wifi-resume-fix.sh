#!/usr/bin/env bash
# Reloads brcmfmac if Wi-Fi doesn't come back after resume — Apple
# Silicon's Broadcom firmware (BCM4378/BCM4387) can wedge across
# s2idle: scans fail with -52 and every association gets rejected with
# status_code=16, which NetworkManager just reports as a wrong
# password. Toggling the radio doesn't reset the chip firmware, only a
# driver reload does. Upstream: AsahiLinux/linux#439.
#
# Adapted fairly closely from Omarchy Mac's omarchy-wifi-resume-fix
# (omarchy-mac/omarchy-mac, bin/) rather than reimplemented from
# scratch — the journal-cursor-based wedge detection here is subtle
# (immune to the clock stepping backwards across resume, which a
# --since window isn't) and worth keeping intact rather than risking a
# simpler-looking rewrite that's subtly wrong.
#
# Installed as a systemd service by install.sh, ordered after
# suspend.target, only on hardware where the Broadcom chip's PCI ID
# matches (see is_apple_silicon_wifi() in install.sh) — a no-op
# anywhere else. Output goes to the journal:
#   journalctl -u tekkiech-rice-wifi-resume-fix
#
# UNTESTED — adapted from a real, shipped implementation, but this
# specific copy has never run against real wedged firmware. Needs the
# actual M1 Pro to confirm.
set -uo pipefail

WAIT_BEFORE=12
WAIT_AFTER=30
REJECTS=2

START=$(date '+%Y-%m-%d %H:%M:%S')
CURSOR=$(journalctl -q -n 0 --show-cursor 2>/dev/null | sed -n 's/^-- cursor: //p')

wifi_iface() {
    nmcli -t -f DEVICE,TYPE device status 2>/dev/null | awk -F: '$2 == "wifi" { print $1; exit }'
}

wifi_state() {
    nmcli -t -f DEVICE,STATE device status 2>/dev/null | awk -F: -v d="$1" '$1 == d { print $2; exit }'
}

REJECT_SIGNATURE='CTRL-EVENT-ASSOC-REJECT.*status_code=16\b'

wedged() {
    local n
    if [ -n "$CURSOR" ]; then
        n=$(journalctl -q --after-cursor "$CURSOR" -t wpa_supplicant --no-pager 2>/dev/null | grep -c "$REJECT_SIGNATURE")
    else
        n=$(journalctl -q --since "$START" -t wpa_supplicant --no-pager 2>/dev/null | grep -c "$REJECT_SIGNATURE")
    fi
    [ "${n:-0}" -ge "$REJECTS" ]
}

if [ "$(nmcli radio wifi 2>/dev/null)" = "disabled" ]; then
    echo "wifi radio is disabled, nothing to do"
    exit 0
fi

IFACE="$(wifi_iface)"
: "${IFACE:=wlan0}"

i=0
state=""
while [ "$i" -lt "$WAIT_BEFORE" ]; do
    state="$(wifi_state "$IFACE")"
    if [ "$state" = "connected" ]; then
        echo "wifi back after ${i}s on $IFACE - no reload needed"
        exit 0
    fi
    if wedged; then
        echo "wedged firmware confirmed after ${i}s (iface=$IFACE state=${state:-none}) - reloading brcmfmac"
        break
    fi
    i=$((i + 1))
    sleep 1
done

if [ "$i" -ge "$WAIT_BEFORE" ]; then
    echo "wifi not back after ${WAIT_BEFORE}s (iface=$IFACE state=${state:-none}) - reloading brcmfmac"
fi

if ! modprobe -r brcmfmac_wcc brcmfmac; then
    echo "failed to unload brcmfmac - giving up, a reboot is needed"
    exit 1
fi
sleep 1
if ! modprobe brcmfmac; then
    echo "failed to reload brcmfmac - giving up, a reboot is needed"
    exit 1
fi
echo "brcmfmac reloaded, waiting for NetworkManager to reconnect"

i=0
while [ "$i" -lt "$WAIT_AFTER" ]; do
    IFACE="$(wifi_iface)"
    : "${IFACE:=wlan0}"
    state="$(wifi_state "$IFACE")"
    if [ "$state" = "connected" ]; then
        echo "reconnected ${i}s after reload on $IFACE"
        exit 0
    fi
    i=$((i + 1))
    sleep 1
done

echo "still not connected ${WAIT_AFTER}s after reload (iface=$IFACE state=${state:-none})"
exit 1
