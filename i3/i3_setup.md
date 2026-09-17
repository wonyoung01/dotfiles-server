# i3 setup — reproducible notes

A record of how this i3 desktop is configured, so it can be reviewed and rebuilt
on a fresh machine. Target: **Ubuntu 24.04, X11, GDM**, i3 4.24.

Theme throughout: **Catppuccin Mocha** (`base #1e1e2e`, `blue #89b4fa`,
`mauve #cba6f7`, `red #f38ba8`, `surface0 #313244`, `text #cdd6f4`).
Monitors: **DP-0** primary 2560×1440, **HDMI-0** 1920×1080 to its left.

> **Two i3 gotchas referenced throughout**
> 1. `exec_always` re-runs on **restart/login**, *not* on plain `reload`
>    (`$mod+Shift+c`). After changing an `exec`/`exec_always` line, use
>    `$mod+Shift+r` (restart) or log out/in. Keybinds (`bindsym`) *do* apply on reload.
>    (Re-verified 2026-09-17 with a canary `exec_always touch …`: `i3-msg reload`
>    returned `success` and never fired it; `restart` did. Polybar likewise only
>    relaunches on restart.)
> 2. The **Write/Edit tooling strips Nerd Font Private-Use-Area glyphs**. Icon
>    glyphs in polybar/dunst configs must be injected with `printf '\uXXXX'` or a
>    `python3` heredoc, then verified with `hexdump -C`.

---

## 0. Dependencies

```bash
sudo apt install i3 polybar rofi feh flameshot blueman dunst kitty i3lock \
                 ibus ibus-hangul im-config fonts-noto-cjk
# Nerd Font (Meslo) installed to ~/.local/share/fonts or /usr/share/fonts, then: fc-cache -f
# PipeWire/WirePlumber provides `wpctl` (volume). Wine provides KakaoTalk.
# xdg-desktop-portal-gtk provides the dark-mode portal for Chrome.
```

## 1. Files created / modified

`~/.config/i3` is a **dotbot symlink → `~/dotfiles/i3`** (entry in
`~/dotfiles/install.conf.yaml`, gated `if: [ "$(uname)" = Linux ]`). Everything in
that folder — including this file — is tracked in the dotfiles repo; `i3/*.bak` is
gitignored. The polybar / rofi / dunst files below are *not* in the repo yet.

| Path | Purpose |
|---|---|
| `~/.config/i3/config` | Main i3 config (all keybinds, autostarts, gaps/borders) |
| `~/.config/i3/next-empty-ws.sh` | Helper: jump/move to next empty workspace (skips 11–36) |
| `~/.config/i3/wallpaper.png` | Radial-gradient Catppuccin wallpaper (feh) |
| `~/.config/i3/i3_setup.md` | This document |
| `~/.config/polybar/config.ini` | Two-bar (main/secondary) Catppuccin polybar |
| `~/.config/polybar/launch.sh` | Per-monitor launcher (tray only on primary) |
| `~/.config/rofi/config.rasi` + `catppuccin-mocha.rasi` | rofi drun/window theme |
| `~/.config/rofi/powermenu.sh` + `powermenu.rasi` | rofi power menu |
| `~/.config/dunst/dunstrc` | Catppuccin notifications, large font |
| `~/.config/fontconfig/conf.d/10-nerd-font-pua.conf` | Strip PUA from CJK fonts |
| `~/.config/xdg-desktop-portal/portals.conf` | Force gtk Settings portal (Chrome dark) |
| `~/.xinputrc` | `run_im ibus` (set via `im-config -n ibus`) |
| `~/.local/share/applications/kakaotalk.desktop` | Wine KakaoTalk in rofi |
| `/etc/default/keyboard` | **System** Caps→Esc (`XKBOPTIONS`) — needs sudo |

---

## 2. Keyboard & input

### Caps Lock → Escape  (system-level, the reliable way)
Set in `/etc/default/keyboard` rather than via an i3 `exec` — an i3 `setxkbmap`
races GNOME's keyboard SettingsDaemon (autostarted by `dex`) and the empty X
default at login, so it was applying inconsistently.

```bash
sudo sed -i 's/^XKBOPTIONS=.*/XKBOPTIONS="caps:escape"/' /etc/default/keyboard
sudo dpkg-reconfigure -f noninteractive keyboard-configuration   # apply now
```
Because `gsettings org.gnome.desktop.input-sources xkb-options` already holds
`['caps:escape']`, both authorities now agree → no race. (Current live value also
includes `keypad:pointerkeys`.)

### Vim-style window nav (`bindsym`, in i3 config)
- Focus: `$mod+h/j/k/l`  (+ arrows `$mod+Down/Up`)
- Move:  `$mod+Shift+h/j/k/l`  (+ `$mod+Shift+arrows`)
- `$mod+h` took over focus-left, so **horizontal split moved to `$mod+b`**.

### Korean (Hangul) input — see §9.

---

## 3. Appearance

### GTK dark mode (i3 autostart)
```
exec_always --no-startup-id gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'
exec_always --no-startup-id gsettings set org.gnome.desktop.interface gtk-theme 'Adwaita-dark'
```

### Chrome dark mode (the device-theme fix)
Chrome reads `org.freedesktop.appearance color-scheme` from the **xdg-desktop-portal**.
Out of the box i3 had no Settings portal backend, so Chrome saw "light".
`~/.config/xdg-desktop-portal/portals.conf`:
```ini
[preferred]
default=gtk
org.freedesktop.impl.portal.Settings=gtk
```
Then `systemctl --user restart xdg-desktop-portal`. (Chrome flag
`chrome://flags` → *not* needed once the portal answers.)

### Gaps & borders (Catppuccin)
`gaps inner 0 / outer 0`, `smart_gaps on`, `smart_borders on`,
`default_border pixel 2`, `for_window [class=".*"] border pixel 10` (no title bars).
Catppuccin `client.*` colors (focused = blue `#89b4fa`). On-the-fly gap tweaks:
`$mod+plus / $mod+minus / $mod+Shift+g`.

### Wallpaper
```
exec_always --no-startup-id feh --bg-fill ~/.config/i3/wallpaper.png
```
Generated with: `convert -size 2560x1440 radial-gradient:'#1e1e2e'-'#11111b' wallpaper.png`.

### Monitor layout — *currently commented out*
A `xrandr --output HDMI-0 --auto --output DP-0 --auto --primary --right-of HDMI-0`
line exists in the config but is **commented out** (the display manager already
arranges the monitors at login). Uncomment it if a fresh machine comes up with
the wrong arrangement. Note the output is `HDMI-0`, not `HDMI-00`.

---

## 4. Polybar  (replaces i3bar)

- Launched by `exec_always --no-startup-id ~/.config/polybar/launch.sh`; the old
  `bar { }` block is commented out.
- **Two-bar `inherit` pattern**: `[bar/main]` (primary, has the `tray` module) and
  `[bar/secondary]` (`inherit = bar/main`, no tray). `launch.sh` gives the primary
  monitor `main`, all others `secondary` — avoids the *"Systray selection already
  managed"* crash from two bars fighting over the tray.
- Modules: i3 / xwindow / filesystem / memory / cpu / pulseaudio / wired / date /
  powermenu / tray. Font: *MesloLGL Nerd Font*.
- `[module/i3]` has `index-sort = true` **and `strip-wsnumbers = true`**: the letter
  workspaces are named `11:A` … `36:Z` (§6) so they sort after 1–10, and the prefix
  is stripped so the bar shows just `A`. `label-mode` renders the active binding mode
  (`resize` / `go`) as a peach chip.
- **Nerd Font icons** (e.g. power ``, hdd ``) were injected via a
  `python3` heredoc and verified with `hexdump -C` (`ef 82 a0` = U+F0A0) — see §8
  for the related CJK/PUA conflict that made the power icon render as a Korean glyph.
- Reload caveat: editing the i3 `bar` doesn't restart polybar; `launch.sh` kills and
  re-launches. A stale `i3bar`/`i3status` left running once showed a red bar at the
  bottom — kill leftover PIDs if that happens.

## 5. Rofi

- App launcher: `$mod+Return` → `rofi -show drun`
- Window switcher: `$mod+Tab` → `rofi -show window`
- Power menu: `$mod+Shift+e` → `~/.config/rofi/powermenu.sh` (lock/suspend/logout/
  reboot/shutdown, themed `powermenu.rasi`)
- Theme: `config.rasi` imports `catppuccin-mocha.rasi`.

---

## 6. Keybindings & autostarts (quick reference)

### Launching / windows
| Key | Action |
|---|---|
| `$mod+t` | kitty terminal (`GLFW_IM_MODULE=ibus` for Hangul) |
| `$mod+Return` | rofi app launcher |
| `$mod+Tab` | rofi window switcher |
| `$mod+Shift+q` | kill window |
| `$mod+f` | fullscreen |
| `$mod+s / w / e` | layout stacking / tabbed / toggle-split |
| `$mod+Shift+space` | floating toggle · `$mod+a` focus parent |
| `$mod+b` | **split horizontal → open launcher** (fills new split) |
| `$mod+v` | **split vertical → open launcher** |
| `$mod+r` | resize mode (hjkl/arrows, Enter/Esc to exit) |

### Workspaces
| Key | Action |
|---|---|
| `$mod+1..0` | switch to workspace 1–10 |
| `$mod+Shift+1..0` | move window to workspace 1–10 |
| `$mod+Left / $mod+Right` | previous / next workspace |
| `$mod+Escape` | back-and-forth (last workspace) |
| `$mod+n` | **next empty workspace** (then opens launcher) |
| `$mod+Shift+n` | **move window to a fresh empty workspace** and follow |
| `$mod+g` then `a`…`z` | **letter workspace A–Z** (`go` mode, see below) |
| `$mod+g` then `Shift+a`…`Shift+z` | move window to letter workspace (stay put) |
| `$mod+g` then `Esc` / `Return` / `$mod+g` | cancel `go` mode |

`next-empty-ws.sh` asks i3 for `get_workspaces`, picks the lowest unused positive
integer **outside the reserved 11–36 letter range**, and either switches (+ opens
rofi) or moves the focused container there.

### Letter workspaces A–Z (`go` mode)
Only 12 `$mod+<letter>` chords were free (c d g i m o p q u x y z), so the 26 letter
workspaces live behind a **binding mode** instead of direct chords: `$mod+g` arms
`mode "go"`, one letter jumps, `Shift+letter` moves the focused container, and every
binding ends with `mode "default"`. `$mod+Shift+g` (gaps) is unaffected.

- Names are `"11:A"` … `"36:Z"` (`set $wsA "11:A"` …), bound with
  `workspace number $wsA`. i3 derives `num` from the prefix, so they sort *after*
  1–10; plain `"A"` would get `num = -1` and polybar's `index-sort` would pile them
  in front of workspace 1. polybar `strip-wsnumbers = true` hides the prefix.
- Because 11–36 are now spoken for, `next-empty-ws.sh` skips that range — otherwise
  `$mod+n` would eventually create a bare `11` sitting on A's slot.
- Like the numbered ones they're ephemeral: created on first use, gone when empty.

### System
| Key | Action |
|---|---|
| `$mod+Shift+x` | lock now (`i3lock -c 1e1e2e`) |
| `$mod+Shift+s` | flameshot region · `$mod+Ctrl+s` full-screen to clipboard · `Print` region |
| `$mod+Shift+b` | blueman-manager (Bluetooth) |
| `XF86Audio*` | volume/mute via `wpctl` (PipeWire) — `pactl` is not installed |
| `$mod+Shift+minus` / `$mod+grave` | scratchpad move / show |
| `$mod+Shift+c` / `$mod+Shift+r` | reload / restart i3 |

`focus_follows_mouse no` + `mouse_warping none` — pointer movement never steals focus.

### Autostarts (`exec` / `exec_always`)
`dex --autostart`, `nm-applet`, `blueman-applet`, `ibus-daemon -drxR`,
GTK dark-mode gsettings, `feh` wallpaper, idle-disable block (§ below), polybar.

### No idle blank / lock / suspend
```
exec_always --no-startup-id xset s off s noblank -dpms
exec_always --no-startup-id gsettings set org.gnome.settings-daemon.plugins.power idle-dim false
exec_always --no-startup-id gsettings set org.gnome.settings-daemon.plugins.power sleep-inactive-ac-type 'nothing'
exec_always --no-startup-id gsettings set org.gnome.settings-daemon.plugins.power sleep-inactive-battery-type 'nothing'
```
- `xset` kills the X screensaver (`s off` → timeout 0) + DPMS — this is what was
  blanking the screen at 10 min **and** triggering the lock.
- **The `xset` line must stay a single invocation.** It used to be two
  `exec_always` lines (`xset s off -dpms` / `xset s noblank`). i3 spawns every
  `exec_always` concurrently, and `xset s noblank` is a *read-modify-write* of the
  whole screensaver tuple (timeout, cycle, blanking, exposures): if it reads before
  `s off` writes and writes after, it puts X's default **600 s** back. Under login
  load (dex firing ~40 XDG autostarts) this lost **181/400** races in a stress test;
  the single-invocation form lost **0/400**. The tell-tale live state after a lost
  race is `timeout: 600 · prefer blanking: no · DPMS Disabled` — the other two
  settings applied, only the timeout got clobbered. Symptom (2026-09-17): a plain
  black screen after 10 min idle with monitors still powered (X's own screensaver
  window; DPMS really was off), dismissed by any key.
- A lost race **persists for the whole session**, because `reload` doesn't re-run
  `exec_always` (gotcha #1). Fix live with `xset s off s noblank -dpms` or
  `$mod+Shift+r`. Quick check: `xset q | grep -A2 'Screen Saver'` → `timeout: 0`.
- If a blank ever recurs with the single line in place, the next suspect is
  `/etc/xdg/autostart/org.gnome.SettingsDaemon.Power.desktop` (`gsd-power`, launched
  by `dex`, currently not surviving) re-arming X after i3 — then switch to a
  periodic re-assert instead of a one-shot.
- `xss-lock` (lock-on-suspend) is **commented out** — manual lock stays on `$mod+Shift+x`.
- Laptop caveat: closing the lid still suspends via systemd-logind; set
  `HandleLidSwitch=ignore` in `/etc/systemd/logind.conf` (sudo) if needed.

---

## 7. Notifications (dunst)

`~/.config/dunst/dunstrc`: Catppuccin colors, *MesloLGL Nerd Font 13*,
`corner_radius 14`, `width = (300, 460)`, `height = 300` (single int in dunst 1.9),
`icon_theme = "Yaru, Adwaita"`, per-urgency frame colors (low blue / normal mauve /
critical red, critical `timeout 0`). Restart with `killall dunst; setsid dunst &`
(this version has no `dunstctl reload`).

## 8. Nerd Font ↔ CJK PUA fix

The power icon rendered as a stray Korean/Chinese glyph because **UnDotum** (and
Noto CJK) advertise glyphs in the Private Use Area (U+E000–U+F8FF) where Nerd Font
icons live, and won generic fontconfig matching. Diagnose:
`fc-match ":charset=f011"` → if it returns a CJK font, that's it.

Fix: `~/.config/fontconfig/conf.d/10-nerd-font-pua.conf` with `target="scan"` rules
that `<minus>` the `0xe000–0xf8ff` range from UnDotum / UnBatang / Noto Sans CJK /
Noto Serif CJK, then `fc-cache -f`. Hangul/CJK text is unaffected (those glyphs are
in their real Unicode blocks). Durable across restarts; fixes all apps.

## 9. Korean (Hangul) input

```bash
im-config -n ibus            # writes ~/.xinputrc = "run_im ibus"
```
- `exec_always --no-startup-id ibus-daemon -drxR` in i3.
- Toggle English/Korean with **Win+Space** (ibus two-engine switch). `$mod+space`
  (`focus mode_toggle`) is intentionally **commented out** so it's free for IME.
- **kitty needs `GLFW_IM_MODULE=ibus`** in its launch env (already in the `$mod+t`
  bind) — without it, kitty ignores ibus.
- Configure engines in `ibus-setup` (add *Hangul*). `ibus-hangul` package required.

## 10. KakaoTalk (Wine) in rofi

`~/.local/share/applications/kakaotalk.desktop` launches the Wine exe with its
`WINEPREFIX`, so it shows up in `$mod+Return` (drun). `StartupWMClass=kakaotalk.exe`,
Korean keywords included. Refresh the menu cache with:
```bash
update-desktop-database ~/.local/share/applications
```

---

## Reproduce from scratch (checklist)

1. `apt install` the §0 dependencies; install the Meslo Nerd Font + `fc-cache -f`.
2. `cd ~/dotfiles && ./install` links `~/.config/i3` (dotbot); drop the remaining §1
   files (polybar / rofi / dunst / fontconfig / portal) into place by hand.
3. `sudo` edit `/etc/default/keyboard` → `XKBOPTIONS="caps:escape"` + `dpkg-reconfigure`.
4. `im-config -n ibus`; add Hangul in `ibus-setup`.
5. Install the fontconfig PUA file (§8) → `fc-cache -f`.
6. Portal file (§3) → `systemctl --user restart xdg-desktop-portal` for Chrome dark.
7. `update-desktop-database ~/.local/share/applications` for KakaoTalk.
8. Generate the wallpaper (§3) or drop your own at `~/.config/i3/wallpaper.png`.
9. `chmod +x ~/.config/i3/next-empty-ws.sh` and `~/.config/polybar/launch.sh`.
10. Restart i3 (`$mod+Shift+r`) or log out/in so all `exec_always` lines fire.

## Known caveats / possible v2

- **No compositor** — no transparency/shadows/vsync. Add `picom` for that.
- **System default terminal** (`x-terminal-emulator`) is still gnome-terminal; only
  i3's `$mod+t` opens kitty. Run `sudo update-alternatives --config x-terminal-emulator`
  to make kitty the global default.
- **`$mod+space`** is traded away to the IME toggle (Win+Space).
- **Monitor `xrandr` line is commented out** — re-enable if a fresh login mis-arranges
  the displays.
- dunst icon theme falls back to Yaru/Adwaita (Papirus not installed).
- Only `~/.config/i3` is in the dotfiles repo so far; polybar / rofi / dunst /
  fontconfig / portal configs from §1 are still machine-local.
