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

**All six mockup surfaces are built**: bar, launcher, control center,
notifications, OSD, and lock screen. See "What's stubbed" below for the
handful of things that are still cosmetic placeholders rather than fully
matching the mockup.

## What's here

```
hypr/hyprland.conf              Hyprland config (bar exec, blur, keybinds)
quickshell/tekkiech/
  shell.qml                     entry point — instantiates all six modules
  pam/password.conf              PAM config for the lock screen
  modules/Bar.qml                 top bar: workspaces, window title, clock, battery, wifi/bt/mic, power
  modules/Launcher.qml            app launcher overlay (SUPER+R)
  modules/ControlCenter.qml       quick settings (SUPER+C): toggles, volume/brightness, media, power row
  modules/Notifications.qml       top-right toast stack
  modules/OSD.qml                 volume/brightness popup
  modules/LockScreen.qml          lock screen (SUPER+L) — real PAM auth
  modules/LockContext.qml         PAM wiring, adapted from Quickshell's official example
  modules/common/Theme.qml        color/font tokens ported from the mockup
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
clock in the middle, battery % and a power glyph on the right).

- `SUPER+Return` — open `foot`
- `SUPER+R` — toggle the launcher (type to filter, `Enter` launches the
  top result, `Esc` or click outside closes it)
- `SUPER+C` — toggle the control center
- `SUPER+L` — lock the screen (real password auth via PAM — it'll check
  your actual login password; `Esc` does *not* bypass it, that's the
  point)
- volume/brightness media keys — show the OSD popup
- `SUPER+SHIFT+Q` — exit Hyprland back to the TTY

**Careful with `SUPER+L`** the first time: if the PAM wiring has a bug,
you could end up locked out with no way back in except a fresh
`Hyprland` process from another TTY (`Ctrl+Alt+F2` etc.) to kill the
stuck one, or a VM console reset. Worth trying it once deliberately
rather than fat-fingering it.

### Taking a screenshot

```bash
grim screenshot.png
```

That captures the whole screen. Grab the file off the VM however your
setup allows (`scp`, a shared folder, or the VM console's own tools) and
send it over — that's what I need to actually see whether the layout,
blur, and fonts are landing the way the mockup intended.

## What's stubbed (for now)

Everything backend-side is wired to real data: Hyprland IPC (workspaces,
window title), UPower (battery), Pipewire (volume, media via MPRIS),
`nmcli`/`bluetoothctl`/`brightnessctl` (Wi-Fi, Bluetooth, brightness —
Quickshell has no native service for any of these, confirmed against its
own source), and real PAM auth for the lock screen.

What's still placeholder-only:

- **Icons** — bluetooth/mic/power/lock/sleep/restart/shutdown all render
  as plain text labels (`"bt"`, `"lock"`, `⏻`, etc.), not the mockup's
  stroke-SVG icons. This is the biggest remaining visual gap vs. the
  mockup.
- **DND ("Focus" toggle)** in the control center is UI-only — flipping
  it doesn't actually suppress notifications yet (would need a shared
  singleton between ControlCenter.qml and Notifications.qml).
- **Control center and the bar each poll Wi-Fi/Bluetooth status
  independently** (duplicated, not shared state) — harmless but a bit
  wasteful; a candidate for a future shared-service refactor.

None of this should block testing the actual functionality — layout,
blur, type, and whether the toggles/sliders/lock/notifications really
work. Flag anything broken in your screenshot feedback.

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
