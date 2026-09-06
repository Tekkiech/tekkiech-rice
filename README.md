# tekkiech-rice

A minimal, monochrome Sway rice — pitch black, Rubik/IBM Plex Mono
typography, no gradients, built from lightweight standard wlroots-ecosystem
tools rather than a custom Qt/QML shell. Design direction was pulled from
[Caelestia](https://github.com/caelestia-dots/caelestia),
[Noctalia](https://github.com/noctalia-dev/noctalia-shell),
[end-4/dots-hyprland](https://github.com/end-4/dots-hyprland), and
[Omarchy](https://github.com/basecamp/omarchy). The mockup this is built
from lives in [`/mockup`](./mockup) (also published as a
[Claude Design canvas](https://claude.ai/code/artifact/e3961e70-2dd7-49f1-9abf-06de383559f4)).

## Status

**Rebuilt on Sway, live-tested on the VM.** This repo originally
targeted Hyprland + Quickshell (still in git history — see `git log` —
if you want to compare). Swapped for a lighter stack: no Qt/QML
runtime, just Sway's own bar plus a handful of small, standard,
single-purpose tools. Bar, launcher, notifications, and the power menu
are all confirmed working; the lock screen is confirmed to *activate*
correctly (real `swaylock` process, no errors) but its actual look
couldn't be screenshotted — `swaylock` blocks screencopy while active,
which is a real security property, not a bug (see "What's stubbed").

## What's here

```
sway/
  config                    Sway config (i3-compatible): keybinds, bar, autostart
  scripts/
    status.sh                 swaybar status_command — i3bar JSON protocol, plain poll loop
    volume.sh                  wpctl wrapper, reports to wob's pipe
    brightness.sh                brightnessctl wrapper, reports to wob's pipe
    wob-daemon.sh                 sets up wob's input pipe
    powermenu.sh                   rofi-driven lock/sleep/restart/shutdown menu (SUPER+SHIFT+P)
rofi/
  config.rasi                default rofi config (modi, icon theme)
  theme.rasi                  the actual look — matches Launcher.dc.html in /mockup
dunst/dunstrc               notification daemon config — matches Notifications.dc.html
wob/wob.ini                 volume/brightness OSD popup — matches OSD.dc.html
install.sh                  package install + config symlinks + service enables
mockup/                     the original design canvas (.dc.html source)
```

## What changed from the Quickshell version, and why

You flagged Quickshell as too heavy for what it was doing — fair, a full
Qt Quick runtime for a status bar is a lot of surface area. This version
trades some visual fidelity to the mockup for a much smaller dependency
footprint and no custom QML to maintain:

- **Bar**: `swaybar` (built into Sway) instead of a custom QML panel. Its
  `status_command` is a plain bash script (`scripts/status.sh`) polling
  the same data sources as before (`wpctl`, `nmcli`, `bluetoothctl`,
  `/sys/class/power_supply`), formatted as i3bar-protocol JSON. Real
  constraint worth knowing: i3bar's protocol has no "center" and no way
  to inject anything between the workspace buttons (which swaybar draws
  itself) and the status blocks — so the window title ends up grouped
  with the other right-side info, not sitting right after the workspaces
  like in the mockup. Waybar could do that layout, but it's GTK-based
  and heavier; this is the tradeoff for staying this light.
- **Control center → gone**, replaced by two things: swaybar's native
  systray (showing real applets — `nm-applet`, `blueman-applet` — not
  custom-built toggles) for Wi-Fi/Bluetooth, and a rofi-driven power menu
  (`scripts/powermenu.sh`, `SUPER+SHIFT+P`) for lock/sleep/restart/
  shutdown. No volume/brightness sliders in a panel — those are
  keybind + OSD only now (see below).
- **Launcher**: `rofi-wayland` instead of a custom QML overlay. Themed in
  `rofi/theme.rasi` to match the mockup's launcher panel as closely as
  rofi's theming language allows.
- **Notifications**: `dunst` instead of a custom `NotificationServer`
  QML component. Dunst has had proper Wayland/layer-shell support for a
  while.
- **OSD**: `wob` — genuinely does one thing (show a bar, hide it after a
  timeout), about as light as this gets. Volume/brightness keybinds pipe
  a number into it directly.
- **Lock screen**: `swaylock` instead of a hand-built `WlSessionLock` +
  PAM QML component. It's *the* standard Sway lock tool, already does
  real PAM auth, no reason to reinvent it. `swayidle` handles auto-lock
  on timeout and lock-before-sleep.
- **No compositor blur or rounded window corners.** Hyprland's
  `decoration.blur` doesn't exist in vanilla Sway — that's a
  `swayfx` (a Sway fork) feature. Went with vanilla Sway for staying
  lighter and not depending on a fork; panels are solid near-black
  instead of frosted glass. rofi/dunst/wob still round their *own*
  corners via their individual configs, so panels/toasts/the OSD keep
  some roundness — it's specifically window/bar blur that's gone. If you
  want that back later, swapping in `swayfx` is a drop-in compositor
  replacement, not a rebuild.

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

Installs Sway and the tools listed above, symlinks `sway/`, `rofi/`,
`dunst/`, `wob/` into `~/.config`, and enables `seatd`/`NetworkManager`/
`bluetooth`. Read it before running it — it's short and every step is
commented.

### Before starting Sway: check GPU acceleration

Same consideration as any wlroots compositor — Sway needs a working DRM
render node:

```bash
ls /dev/dri
```

If that's empty or Sway fails to start with a GBM/DRM error, force
software rendering:

```bash
export WLR_RENDERER=pixman
```

### Starting Sway

No display manager set up — for testing, log into a TTY and run:

```bash
sway
```

- `SUPER+Return` — open `foot`
- `SUPER+d` — app launcher (rofi)
- `SUPER+SHIFT+p` — power menu (lock/sleep/restart/shutdown)
- `SUPER+l` — lock immediately
- volume/brightness media keys — adjust + show the OSD popup
- `SUPER+SHIFT+q` — exit Sway back to the TTY

### Taking a screenshot

```bash
grim screenshot.png
```

## What's stubbed / verified

Verified working live on the test VM, screenshots taken:

- **Bar** — workspace pill, live window title (jq-filtered to actual
  windows only, not empty workspace containers), volume %, clock/date,
  systray with real `nm-applet`/`blueman-applet` icons.
- **Launcher** (rofi) — real app list from `.desktop` entries, icons,
  correct dark theme including the selected-row highlight.
- **Notifications** (dunst) — a real `notify-send` rendered correctly.
- **Power menu** (rofi) — Lock/Sleep/Restart/Shutdown/Cancel, correctly
  themed.

Not fully verified:

- **Lock screen appearance** — `swaylock` starts cleanly (confirmed via
  process list, no errors in its log) but `grim` returns a blank black
  frame while it's active. That's `swaylock`/wlroots deliberately
  blocking screencopy during a lock — a real security property (it
  stops screenshot tools from being used to inspect or bypass a locked
  screen), not something to work around. You'll need to actually look
  at the VM console to see how it renders. Same caution as before:
  `SUPER+l` triggers *real* PAM password auth against your actual login
  password — try it once deliberately before relying on it, and know
  that killing the whole `sway` process (from another TTY, or via SSH:
  `pkill -x sway`) is the clean escape hatch if something's wrong,
  since there's no bypass by design.
- **Wi-Fi / Bluetooth status** — this VM has no wireless or Bluetooth
  hardware at all (`nmcli dev wifi` and `bluetoothctl show` both come
  back empty/off), so those bar blocks and tray icons have never had
  anything real to display. The code path is exercised (doesn't hang,
  doesn't error — that was the whole `timeout` fix above) but the
  actual "shows the right SSID" / "actually toggles Bluetooth" behavior
  needs real hardware to confirm.
- **Volume-reactive OSD** (`wob`) — same story as the old Quickshell
  build: no audio hardware on this VM at all, so `volume.sh`/
  `brightness.sh` were checked for syntax and logic but the keybind →
  `wob` popup flow was never actually triggered.
- **Rofi's power-menu placeholder text** — reads "Search apps, files,
  commands…" even in the power menu, since the placeholder is fixed in
  `theme.rasi` rather than driven by `-p`. Cosmetic only.

## Troubleshooting

- **`failed to open seat` / permission errors on start** — install.sh
  enables `seatd` and adds you to the `seat`/`video` groups, but that
  needs a fresh login to take effect. Log out and back in (or open a new
  SSH session) before trying `sway` again.
- **Bar has no icons on the right / tray empty** — `nm-applet` and
  `blueman-applet` need a moment to start after Sway launches (they're
  in `exec` at the bottom of `sway/config`); also confirm
  `NetworkManager`/`bluetooth` services are actually running
  (`systemctl status NetworkManager bluetooth`).
- **Text renders in a generic fallback font** — Rubik is AUR-only
  (`ttf-rubik-vf`); if `install.sh`'s yay step failed or was skipped,
  everything still works, it just won't match the mockup's type exactly.
- **`rofi` looks unthemed / plain** — check `~/.config/rofi` resolves to
  this repo's `rofi/` (`ls -la ~/.config/rofi`), and that the keybind is
  actually passing `-theme ~/.config/rofi/theme.rasi` (see `sway/config`).
- **wob never shows anything** — its input pipe is created by
  `scripts/wob-daemon.sh`, started via `exec` in `sway/config`. Check
  it's actually running (`pgrep -f wob-daemon`) and that
  `$XDG_RUNTIME_DIR/wob.sock` exists as a named pipe (`ls -la
  $XDG_RUNTIME_DIR/wob.sock`).
