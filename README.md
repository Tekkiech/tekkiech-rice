# tekkiech-rice

A minimal, monochrome Hyprland + Quickshell rice — pitch black, Rubik/IBM
Plex Mono typography, no gradients. Design direction was pulled from
[Caelestia](https://github.com/caelestia-dots/caelestia),
[Noctalia](https://github.com/noctalia-dev/noctalia-shell),
[end-4/dots-hyprland](https://github.com/end-4/dots-hyprland), and
[Omarchy](https://github.com/basecamp/omarchy). The mockup this is built
from lives in [`/mockup`](./mockup) (also published as a
[Claude Design canvas](https://claude.ai/code/artifact/e3961e70-2dd7-49f1-9abf-06de383559f4)).

## Status

**First pass: bar + launcher only.** Control center, notifications, OSD,
and lock screen from the mockup aren't built yet — those come next once
this pass is confirmed working. See "What's stubbed" below for what's
faked in the bar for now.

## What's here

```
hypr/hyprland.conf              Hyprland config (bar exec, blur, keybinds)
quickshell/tekkiech/
  shell.qml                     entry point
  modules/Bar.qml                top bar: workspaces, active window title, clock, battery, power
  modules/Launcher.qml           app launcher overlay (SUPER+R)
  modules/common/Theme.qml       color/font tokens ported from the mockup
install.sh                      package install + config symlinks
mockup/                          the original design canvas (.dc.html source)
```

## Installing on a fresh minimal Arch VM

Starting point assumed: a minimal `archinstall` (or equivalent) with just
`base linux linux-firmware`, a normal user with `sudo`, and networking
already up (`ping archlinux.org` should work).

```bash
sudo pacman -Syu
git clone https://github.com/Tekkiech/tekkiech-rice.git
cd tekkiech-rice
chmod +x install.sh
./install.sh
```

This installs Hyprland, Quickshell, a terminal (`foot`), fonts, `grim`
(for screenshots), and symlinks `hypr/` and `quickshell/tekkiech/` into
`~/.config`. Read it before running it — it's short and every step is
commented.

### Before starting Hyprland: check GPU acceleration

Hyprland needs a working DRM render node. Check for one:

```bash
ls /dev/dri
```

If you see `card0`/`renderD128`, you likely have accelerated rendering
(matters if your VM's video device is `virtio-gpu` with 3D/virgl enabled
in libvirt — check the VM's hardware details if unsure). If that
directory is empty or Hyprland fails to start with a GBM/DRM error, force
software rendering instead:

```bash
export WLR_RENDERER=pixman
export LIBGL_ALWAYS_SOFTWARE=1
```

Software rendering works fine for testing layout/look — it's just slower,
and don't be surprised if animations stutter.

### Starting Hyprland

No display manager is set up here — for testing, just log into a TTY and
run:

```bash
Hyprland
```

You should see: a black screen, a 40px bar at the top (workspace `1`,
clock in the middle, battery % and a power glyph on the right). `SUPER
+Return` opens `foot`. `SUPER+R` toggles the launcher — type to filter,
`Enter` launches the top result, `Esc` or click outside closes it.
`SUPER+SHIFT+Q` exits Hyprland back to the TTY.

### Taking a screenshot

```bash
grim screenshot.png
```

That captures the whole screen. Grab the file off the VM however your
setup allows (`scp`, a shared folder, or the VM console's own tools) and
send it over — that's what I need to actually see whether the layout,
blur, and fonts are landing the way the mockup intended.

## What's stubbed (for now)

The bar's workspace list, active window title, clock, and battery are
wired to real Hyprland/UPower data. Wi-Fi/Bluetooth/mic are also live
now, but not via a Quickshell service module — Quickshell has no
built-in network or Bluetooth API (confirmed against its own source:
`src/services/` only has greetd, mpris, notifications, pam, pipewire,
polkit, status_notifier, upower), so the bar polls `nmcli`,
`bluetoothctl`, and `wpctl` on a 5s timer instead, the same way
waybar-style bars typically do this.

Still cosmetic-only placeholders, pending real vector icons:

- **Bluetooth** shows as a plain "bt" text label, dim when off.
- **Mic** shows as "mic muted" text, only when actually muted.
- **Power button** is a plain `⏻` Unicode character, not the mockup's
  stroke-SVG icon.

None of this should block testing the bar/launcher layout, blur, and
type — flag it in your screenshot feedback and I'll fill these in next.

## Troubleshooting

- **`failed to open seat` / permission errors on start** — your session
  isn't getting a seat from `systemd-logind`. Install and enable `seatd`:
  `sudo pacman -S seatd && sudo systemctl enable --now seatd && sudo usermod -aG seat $USER`
  (then log out and back in).
- **Bar shows but has no blur, looks like a flat gray box** — that's
  Hyprland's `decoration.blur`, not Quickshell; confirm
  `~/.config/hypr/hyprland.conf` is actually the symlinked file (`ls -la
  ~/.config/hypr/`) and not a leftover default config.
- **Text renders in a generic fallback font** — Rubik is AUR-only
  (`ttf-rubik-vf`); if `install.sh`'s yay step failed or was skipped,
  everything still works, it just won't match the mockup's type exactly.
- **`qs -c tekkiech` errors about a missing shell.qml** — check
  `~/.config/quickshell/tekkiech` actually resolves (`ls -la
  ~/.config/quickshell/`) to this repo's `quickshell/tekkiech/`.
