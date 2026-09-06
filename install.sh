#!/usr/bin/env bash
# tekkiech-rice install script — minimal Arch Linux, CLI-only.
# Run as your normal user (not root); it uses sudo where needed.
#
# What this does:
#   1. pacman-installs Sway and a lightweight set of companion tools
#   2. builds yay (AUR helper) if you don't have one, for the one AUR font
#   3. symlinks this repo's sway/, rofi/, dunst/, wob/ into ~/.config
#   4. enables the services Sway needs to run without a display manager
#
# See README.md for how to actually start Sway from a TTY.

set -euo pipefail

if [[ $EUID -eq 0 ]]; then
    echo "Run this as your normal user, not root (it calls sudo itself)." >&2
    exit 1
fi

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "==> Detected architecture: $(uname -m)"
echo "    (everything below is plain pacman/AUR — no x86-specific package"
echo "    names or paths in this repo, see README.md's ARM section)"

echo "==> Updating package databases"
sudo pacman -Sy

echo "==> Installing official-repo packages"
sudo pacman -S --needed --noconfirm \
    sway \
    foot \
    rofi-wayland \
    dunst \
    swaybg swaylock swayidle \
    wob \
    grim slurp wl-clipboard \
    brightnessctl \
    power-profiles-daemon \
    jq \
    seatd \
    pipewire pipewire-pulse pipewire-audio wireplumber \
    networkmanager network-manager-applet \
    bluez bluez-utils blueman \
    polkit polkit-gnome \
    xdg-desktop-portal xdg-desktop-portal-wlr \
    ttf-ibm-plex \
    noto-fonts \
    papirus-icon-theme \
    libnotify \
    git base-devel

# --- AUR: yay + ttf-rubik-vf -------------------------------------------
# Rubik (the UI font) isn't in the official repos, only AUR. Skip this
# section if you'd rather manage fonts yourself — everything falls back
# to the system sans font if Rubik isn't installed, it just won't match
# the mockup exactly.
if ! command -v yay >/dev/null 2>&1; then
    echo "==> yay not found, building it"
    tmp_yay="$(mktemp -d)"
    git clone https://aur.archlinux.org/yay-bin.git "$tmp_yay/yay-bin"
    (cd "$tmp_yay/yay-bin" && makepkg -si --noconfirm)
    rm -rf "$tmp_yay"
fi

echo "==> Installing ttf-rubik-vf (AUR)"
yay -S --needed --noconfirm ttf-rubik-vf

# --- Config symlinks -----------------------------------------------------
mkdir -p "$HOME/.config"

for dir in sway rofi dunst wob fontconfig; do
    echo "==> Linking $dir config"
    rm -rf "$HOME/.config/$dir"
    ln -sfn "$REPO_DIR/$dir" "$HOME/.config/$dir"
done

for script in "$REPO_DIR"/sway/scripts/*.sh; do
    chmod +x "$script"
done

# --- Services --------------------------------------------------------------
echo "==> Enabling seatd, NetworkManager, bluetooth, power-profiles-daemon"
sudo systemctl enable --now seatd
sudo systemctl enable --now NetworkManager
sudo systemctl enable --now bluetooth
sudo systemctl enable --now power-profiles-daemon
sudo usermod -aG seat,video "$USER"
echo "    (log out and back in, or open a fresh session, for the group change to apply)"

# Apple Silicon (Asahi) specific fixes — a no-op on x86 or generic ARM,
# see install-apple-silicon.sh's own header for what it checks before
# doing anything.
source "$REPO_DIR/install-apple-silicon.sh"

echo
echo "Done. See README.md for how to start Sway and what to check first."
