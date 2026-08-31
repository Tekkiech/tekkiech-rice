#!/usr/bin/env bash
# tekkiech-rice install script — minimal Arch Linux, CLI-only.
# Run as your normal user (not root); it uses sudo where needed.
#
# What this does:
#   1. pacman-installs Hyprland, Quickshell, a terminal, and fonts
#   2. builds yay (AUR helper) if you don't have one, for the one AUR font
#   3. symlinks this repo's hypr/ and quickshell/tekkiech/ into ~/.config
#
# It does NOT set up a display manager — see README.md for how to start
# Hyprland from a TTY, which is enough for testing.

set -euo pipefail

if [[ $EUID -eq 0 ]]; then
    echo "Run this as your normal user, not root (it calls sudo itself)." >&2
    exit 1
fi

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "==> Updating package databases"
sudo pacman -Sy

echo "==> Installing official-repo packages"
sudo pacman -S --needed --noconfirm \
    hyprland \
    quickshell \
    qt6-base qt6-declarative qt6-svg qt6-wayland \
    foot \
    grim \
    ttf-ibm-plex \
    noto-fonts \
    polkit \
    upower \
    xdg-desktop-portal xdg-desktop-portal-hyprland \
    git base-devel

# --- AUR: yay + ttf-rubik-vf -------------------------------------------
# Rubik (the UI font) isn't in the official repos, only AUR. Skip this
# section if you'd rather manage fonts yourself — the shell falls back to
# the system sans font if Rubik isn't installed, it just won't match the
# mockup exactly.
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

echo "==> Linking hypr config"
mkdir -p "$HOME/.config/hypr"
ln -sf "$REPO_DIR/hypr/hyprland.conf" "$HOME/.config/hypr/hyprland.conf"

echo "==> Linking quickshell config"
mkdir -p "$HOME/.config/quickshell"
ln -sfn "$REPO_DIR/quickshell/tekkiech" "$HOME/.config/quickshell/tekkiech"

echo "==> Enabling upower (battery reporting)"
sudo systemctl enable --now upower

echo "==> Enabling seatd and adding you to the seat + video groups"
sudo systemctl enable --now seatd
sudo usermod -aG seat,video "$USER"
echo "    (log out and back in, or open a fresh session, for the group change to apply)"

echo
echo "Done. See README.md for how to start Hyprland and what to check first."
