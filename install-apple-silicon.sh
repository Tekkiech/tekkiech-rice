#!/usr/bin/env bash
# Apple Silicon (Asahi Linux) specific fixes — sourced from install.sh,
# never run standalone. Every fix here self-gates on real hardware
# detection, so running install.sh on x86 or generic ARM just skips
# this file's body entirely; it's not a separate install path to
# remember to run.
#
# Adapted from Omarchy Mac's install/hardware/apple/*.sh
# (omarchy-mac/omarchy-mac, quattro branch) — real, shipped fixes for
# real, well-documented Apple Silicon quirks, reimplemented for this
# repo's package set rather than pulling in the whole Omarchy binary
# suite. See each function's comment for what upstream issue it's
# working around.
#
# UNTESTED beyond `bash -n` — grounded in Omarchy Mac's real,
# shipped implementation of the same fixes, but this specific copy has
# never run on real Apple Silicon hardware. Needs the actual M1 Pro to
# confirm all four actually fire and actually help.
set -uo pipefail

is_apple_silicon() {
    [ "$(uname -m)" = "aarch64" ] && grep -Faiq 'apple,' /proc/device-tree/compatible 2>/dev/null
}

is_apple_silicon || { echo "==> Not Apple Silicon, skipping Apple-specific fixes"; return 0 2>/dev/null || exit 0; }

echo "==> Apple Silicon detected — applying Asahi-specific fixes"

# --- Speaker safety --------------------------------------------------------
# The kernel keeps Apple Silicon speakers muted on purpose without the
# full stack: asahi-audio carries the UCM profiles and DSP filter chain
# that makes a speaker sink exist at all, speakersafetyd is what
# actually allows them to play (these drivers can be damaged by what
# the hardware will happily ask them to do, hence the daemon gate), and
# rtkit gives pipewire's data threads realtime scheduling — without it
# the Asahi speaker filter chain's several convolvers per cycle are
# exposed to underruns (crackling/popping) under any load spike.
# pipewire-alsa is needed alongside the pipewire-pulse this repo
# already installs.
#
# Assumes the asahi-alarm.org base image's own pacman repo already
# carries asahi-audio/speakersafetyd (they're not in mainline Arch or
# generic Arch Linux ARM) — true for the base this was written against,
# not re-verified here.
echo "==> Installing the Apple Silicon audio stack (speaker protection)"
if sudo pacman -S --needed --noconfirm rtkit pipewire-alsa asahi-audio speakersafetyd; then
    sudo systemctl enable --now speakersafetyd || \
        echo "Warning: speakersafetyd did not start; the speakers will stay muted." >&2
else
    echo "Warning: could not install the Apple Silicon audio stack; the speakers will stay muted." >&2
    echo "         (asahi-audio/speakersafetyd need Asahi's own pacman repo, not just ALARM's)" >&2
fi

# --- Display notch ----------------------------------------------------------
# Asahi crops the display below the notch by default. Without this, the
# bar (anchored to the very top of the screen) would render partly or
# entirely in the cropped-away strip.
if modinfo appledrm &>/dev/null && [ ! -f /etc/modprobe.d/asahi-notch.conf ]; then
    echo "==> Enabling the full display height (notch area) for the bar"
    echo "options appledrm show_notch=1" | sudo tee /etc/modprobe.d/asahi-notch.conf >/dev/null
fi

# --- Keyboard/trackpad boot race --------------------------------------------
# The internal keyboard/trackpad HID devices bind to hid-generic first,
# then get destroyed and recreated once hid_apple/hid_magicmouse load.
# That churn can reshuffle input event minors while udev/logind/the
# compositor are starting; on unlucky boots logind's TakeDevice fails
# for the trackpad and libinput never retries — dead trackpad for the
# whole session. Loading the drivers from the initramfs makes them bind
# correctly on first registration instead.
if [ ! -f /etc/mkinitcpio.conf.d/apple_hid_modules.conf ]; then
    echo "==> Early-loading Apple HID modules (keyboard/trackpad boot-race fix)"
    sudo mkdir -p /etc/mkinitcpio.conf.d
    sudo tee /etc/mkinitcpio.conf.d/apple_hid_modules.conf >/dev/null <<'EOF'
# Name each driver only on kernels that actually build it as a module —
# mkinitcpio fails the whole image over a MODULES entry it can't find.
for _tekkiech_apple_hid_module in hid_apple hid_magicmouse; do
    modinfo -k "${KERNELVERSION:-$(uname -r)}" "$_tekkiech_apple_hid_module" >/dev/null 2>&1 &&
        MODULES+=("$_tekkiech_apple_hid_module")
done
unset _tekkiech_apple_hid_module
EOF
    echo "    Regenerating the initramfs (needed for the above to take effect)"
    sudo mkinitcpio -P || echo "Warning: mkinitcpio -P failed; re-run it by hand." >&2
    echo "    A reboot is needed for this fix to take effect."
fi

# --- Wi-Fi resume wedge ------------------------------------------------------
# BCM4378 (14e4:4425) and BCM4387 (14e4:4433) — the Wi-Fi chips in most
# M1/M2 Macs — can wedge across sleep: NetworkManager reports "wrong
# password" on resume when it's actually the firmware, and only a
# driver reload clears it. Installs a service that checks for the wedge
# signature after every resume and reloads brcmfmac if needed. Gated on
# the actual PCI ID, not just "is Apple Silicon" — M2 Max/Ultra's
# BCM4388 does not have this bug (verified upstream on real hardware,
# not assumed), and this must stay a no-op there.
if lspci -nn 2>/dev/null | grep -qE "14e4:(4425|4433)"; then
    echo "==> Detected BCM4378/BCM4387 Wi-Fi — installing resume-wedge recovery"
    sudo install -Dm755 "$REPO_DIR/sway/scripts/apple-wifi-resume-fix.sh" \
        /usr/local/bin/tekkiech-rice-wifi-resume-fix

    sudo tee /etc/systemd/system/tekkiech-rice-wifi-resume-fix.service >/dev/null <<'EOF'
[Unit]
Description=Reload brcmfmac if Wi-Fi does not return after resume
After=suspend.target hibernate.target hybrid-sleep.target suspend-then-hibernate.target
After=NetworkManager.service

[Service]
Type=oneshot
ExecStart=/usr/local/bin/tekkiech-rice-wifi-resume-fix
TimeoutStartSec=120

[Install]
WantedBy=suspend.target hibernate.target hybrid-sleep.target suspend-then-hibernate.target
EOF
    sudo systemctl enable tekkiech-rice-wifi-resume-fix.service
fi
