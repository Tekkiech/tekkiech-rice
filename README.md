# tekkiech-rice

A minimal, monochrome Sway rice — pitch black, Rubik/IBM Plex Mono
typography, no gradients, built from lightweight standard wlroots-ecosystem
tools rather than a custom Qt/QML shell. Design direction was pulled from
[Caelestia](https://github.com/caelestia-dots/caelestia),
[Noctalia](https://github.com/noctalia-dev/noctalia-shell),
[end-4/dots-hyprland](https://github.com/end-4/dots-hyprland), and
[Omarchy](https://github.com/omacom/omarchy). The mockup this is built
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
    kbd-backlight.sh               keyboard backlight, no-ops if there isn't one
    wob-daemon.sh                    sets up wob's input pipe
    lock.sh                            the one themed swaylock invocation, shared by everything below
    powermenu.sh                         rofi-driven lock/sleep/restart/shutdown menu (SUPER+SHIFT+P)
    lid-close.sh                           lid switch handler — lock unless docked (clamshell mode)
    powerprofile.sh                          power-profiles-daemon wrapper, AC/battery-aware (SUPER+SHIFT+E)
    battery-watch.sh                           background loop, notifies once per discharge below 15%
    apple-wifi-resume-fix.sh                     Apple Silicon Wi-Fi wedge recovery (installed by install-apple-silicon.sh)
rofi/
  config.rasi                default rofi config (modi, icon theme)
  theme.rasi                  the actual look — matches Launcher.dc.html in /mockup
dunst/dunstrc               notification daemon config — matches Notifications.dc.html
wob/wob.ini                 volume/brightness OSD popup — matches OSD.dc.html
install.sh                  package install + config symlinks + service enables
install-apple-silicon.sh    Asahi Linux specific fixes — sourced by install.sh, no-op elsewhere
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
- `SUPER+SHIFT+e` — cycle power profile (power-saver/balanced/performance)
- volume/brightness/keyboard-backlight media keys — adjust + show the
  OSD popup (keyboard backlight silently does nothing if your laptop
  doesn't have one)
- closing the lid — locks, unless there's an external monitor connected
  (clamshell mode), in which case it just turns off the internal panel
  and keeps running on the external display
- `SUPER+SHIFT+q` — exit Sway back to the TTY

### Taking a screenshot

```bash
grim screenshot.png
```

## Laptop support

Four things adapted from how [Omarchy](https://github.com/omacom/omarchy)
handles laptops (a much bigger project — 350+ utility scripts in its
`bin/` — these four patterns are what's actually relevant to a rice
this size, reimplemented rather than copied wholesale, in the "no
daemon for one fact" style the rest of this repo already uses):

- **Lid close / clamshell mode** (`sway/scripts/lid-close.sh`, bound
  via `bindswitch lid:on/off` in `sway/config`) — closing the lid locks
  the screen, *unless* an external monitor is connected, in which case
  it's clamshell mode: just turn off the internal panel and keep
  running externally, don't lock or suspend. Reads
  `/proc/acpi/button/lid/*/state` directly and `swaymsg -t get_outputs`
  for the external-monitor check — no extra daemon.
- **Power profiles** (`sway/scripts/powerprofile.sh`, `SUPER+SHIFT+e`
  to cycle, needs `power-profiles-daemon` which `install.sh` now
  installs and enables) — remembers your last-picked profile
  separately for AC and battery power, so plugging in restores
  whichever one you chose for AC rather than always resetting to a
  default. AC/battery state comes from `/sys/class/power_supply`
  directly (Omarchy's version uses a UPower D-Bus property for the
  same fact — same information, lighter path to it). Shows on the bar.
- **Battery-low notification** (`sway/scripts/battery-watch.sh`, a
  background loop from `sway/config`) — one notification when the
  battery drops below 15% while discharging, not one every poll cycle
  once you're under the line; resets when you plug in or charge back
  past it.
- **Keyboard backlight** (`sway/scripts/kbd-backlight.sh`, bound to the
  `XF86KbdBrightness{Up,Down}` keys) — separate from screen brightness.
  Looks for a `brightnessctl`-visible LED device matching
  `*kbd_backlight*` and quietly does nothing if your laptop doesn't
  have one, rather than erroring.

**None of this is tested beyond `bash -n` and a live config-load
check** — this VM has no lid switch, no battery, no `power-profiles-daemon`-
compatible hardware, and no keyboard backlight. The logic is reviewed
by eye and grounded in Omarchy's real (running, shipped) implementation
of the same ideas, but it needs an actual laptop to confirm. If you
test on one, the lid-close branch (locks vs. clamshell) is the one
most worth watching closely.

## ARM support

Nothing in this repo is architecture-specific — no hardcoded
`x86_64` anywhere, every package installs via plain `pacman`/`yay`
using Arch's normal architecture resolution, and confirmed the one AUR
package (`ttf-rubik-vf`, and `yay-bin` itself, which needs a real
binary release rather than just being an "any-arch" package) both ship
`aarch64` builds:

- `ttf-rubik-vf` is a font-only AUR package (`any` arch), works
  identically everywhere.
- `yay-bin`'s upstream (`Jguer/yay`) publishes `aarch64` and `armv7h`
  release tarballs alongside `x86_64` — confirmed on its GitHub
  releases before relying on it, not assumed.
- Everything else in `install.sh` is a mainstream package (`sway`,
  `foot`, `rofi-wayland`, `dunst`, the `pipewire`/`wireplumber` stack,
  etc.) that Arch Linux ARM mirrors from the same upstream sources
  Arch itself uses — no proprietary blobs or x86-only software in this
  stack.
- GPU driver needs vary by ARM board (Panfrost/Lima for Mali GPUs,
  V3D/VC4 for Raspberry Pi, Apple Silicon's own driver stack under
  Asahi) but all route through the same `mesa` package already in
  `install.sh` — no board-specific package swap needed, though which
  *kernel* and firmware you're running is on you, same as the
  GPU-acceleration check earlier in this README.

**Not tested on real ARM hardware** — everything above is verified by
checking package/release metadata, not by actually running this on an
aarch64 machine. If you try it on one, that's the real test.

### Apple Silicon (Asahi Linux)

If you're installing on a real Mac via [Asahi Alarm](https://asahi-alarm.org/)
(this repo was written with an M1 Pro MacBook Pro 14" in mind
specifically), `install-apple-silicon.sh` — sourced automatically by
`install.sh`, not a separate step — applies four fixes for real,
well-documented Apple Silicon quirks, each gated on actual hardware
detection so it's a genuine no-op on x86 or generic ARM:

- **Speaker safety.** Apple Silicon speakers are kept muted **at the
  kernel level** without the full stack (`asahi-audio` +
  `speakersafetyd` + `rtkit`, on top of the `pipewire-pulse` this repo
  already installs) — this isn't a preference, it's hardware
  protection the kernel enforces on purpose. Assumes the
  asahi-alarm.org base image's own pacman repo carries
  `asahi-audio`/`speakersafetyd` (they're not in mainline Arch or
  generic Arch Linux ARM) — true for the base this was written
  against, not independently re-verified.
- **Display notch.** Asahi crops the display below the notch by
  default; without `appledrm show_notch=1`, this rice's top-anchored
  bar would render partly or entirely in the cropped-away strip.
- **Keyboard/trackpad boot race.** The internal keyboard/trackpad can
  come up dead for the whole session on unlucky boots (a device-churn
  race between `hid-generic` and `hid_apple`/`hid_magicmouse`) —
  early-loading those drivers from the initramfs fixes it.
- **Wi-Fi resume wedge** (BCM4378/BCM4387 only, gated on the actual PCI
  ID rather than just "is Apple Silicon" — M2 Max/Ultra's BCM4388
  doesn't have this bug) — the firmware can wedge across sleep, which
  NetworkManager surfaces as a wrongly-rejected Wi-Fi password on
  resume; a systemd service detects and recovers from it.

All four are adapted from [Omarchy Mac](https://github.com/omarchy-mac/omarchy-mac)'s
`install/hardware/apple/*.sh` (real, shipped fixes, not guessed at) —
reimplemented against this repo's own package set rather than pulling
in Omarchy's whole 350+-script `bin/` utility suite, which is a much
bigger project than a rice this size needs. The Wi-Fi resume fix's
wedge-detection logic (journal-cursor-based, clock-skew-safe across
suspend) is adapted fairly closely rather than rewritten simpler and
possibly wrong — same reasoning as the lock screen's PAM wiring
earlier in this repo's history.

**None of the four have run on real hardware yet** — this VM is
x86_64, so every detection gate in `install-apple-silicon.sh`
correctly evaluates false on it (verified: sourcing it here prints
"Not Apple Silicon, skipping" and exits cleanly, so the no-op path at
least doesn't break the x86 install). The actual fixes need the real
M1 Pro to confirm — the display-notch and speaker-safety ones especially,
since without them the machine would be visibly and audibly broken in
an obvious way.

Two things worth knowing about the target base image itself, from
Omarchy Mac's own install notes (not this repo's problem to fix, but
worth having read before you hit them): the minimal Asahi Alarm image
ships without `git` or `sudo` at all (`pacman -S --needed sudo git` as
root, before anything else), and a handful of unrelated packages (e.g.
`obs-studio`, `dotnet-runtime`) have no aarch64 build — none of which
this rice's own package list touches.

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
- **Faint text color fringing on the bar, under screenshot/software
  rendering.** This is a known, long-standing upstream Sway/Cairo bug,
  not something fixable via `fontconfig` (tried — confirmed
  `rgba: none` is correctly applied at the font-matching level, doesn't
  help): Cairo's font rendering breaks specifically when the
  compositing operator is `SOURCE`, which is what swaybar uses for its
  layer-shell surface. See
  [swaywm/sway#5605](https://github.com/swaywm/sway/issues/5605),
  [#3163](https://github.com/swaywm/sway/issues/3163),
  [#8421](https://github.com/swaywm/sway/issues/8421). `waybar` (GTK-
  based) doesn't hit this specific bug, but that's a heavier dependency
  — the same tradeoff already made by choosing swaybar over waybar in
  the first place. Decided to accept this rather than add GTK back in.

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
