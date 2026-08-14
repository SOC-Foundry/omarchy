# omarchy

CLI agent runbook · Omarchy (Arch + Hyprland) operator config ledger.

Not the distro. Execute only user-space changes: `~/.config/**` + this repo.  
**Never** edit `~/.local/share/omarchy/`.

| | |
|---|---|
| Kit | `/data/Development/Projects/socfoundry/omarchy/` |
| Hosts | `p3oos` (desk) · `83te` (Yoga docked) |
| Session rule | Session *N* = `CHG-00N` (no gaps) |
| Backup rule | `*.bak.chg00N.<YYYYMMDD-HHMMSS>` before every edit |
| Next free | **CHG-014** |

```bash
omarchy debug --no-sudo --print
hyprctl monitors
```

---

## Agent protocol

1. Read **Objective · Challenge · Paths · Execute · Backout** for the target CHG.
2. Backup touched files with the backup rule above.
3. Run **Execute**. Stop on failure; do not invent package reverts unless the CHG says so.
4. Confirm with the one-line checks in **Execute** / verify commands.
5. On failure: run **Backout**.
6. New work → next free CHG; append chapter; add **Changelog** row; keep this format.

| Surface | Path |
|---------|------|
| Hyprland | `~/.config/hypr/` |
| Alacritty | `~/.config/alacritty/alacritty.toml` |
| fish / Tide | `~/.config/fish/` |
| WirePlumber / EQ | `~/.config/wireplumber/` · `~/.config/audio-eq/` |
| Scripts | `scripts/chg00N-*` |
| Formal notes | `docs/chg00N-*.md` (optional detail) |

---

## Changelog

| Applied | CHG | Title | Host | Status | Risk | Surfaces |
|---------|-----|-------|------|--------|------|----------|
| 2026-07-05 | [001](#chg-001--the-desk-in-order) | The desk in order | p3oos | Applied | Low | `hypr/monitors.conf` |
| 2026-07-06 | [002](#chg-002--a-prompt-worth-looking-at) | A prompt worth looking at | p3oos · 83te | Applied | Low | fish · Tide · Fisher |
| 2026-07-06 | [003](#chg-003--alacritty-startup) | Alacritty startup | both | Applied | Low | `alacritty.toml` |
| 2026-07-06 / 07-09 | [004](#chg-004--projects-on-their-own-disk) | Projects on their own disk | p3oos · 83te | Applied | **High** | LUKS/XFS `/data` · `scripts/chg004-*` |
| 2026-07-08 | [005](#chg-005--readable-paths) | Readable paths | both | Applied | Low | Tide pwd colors |
| 2026-07-08 | [006](#chg-006--land-in-projects) | Land in Projects | both | Applied | Low | `alacritty.toml` cwd |
| 2026-07-19 | [007](#chg-007--audio-precedence-config) | Audio Precedence Config | 83te | Applied | Med | WP + EQ · `scripts/chg007-*` |
| 2026-07-29 | [008](#chg-008--screenshot-config) | Screenshot Config | 83te | Applied | Low | `OMARCHY_SCREENSHOT_DIR` · bind |
| 2026-08-05 | [009](#chg-009--center-monitor-swap) | Center monitor swap | 83te | Applied | Low | `monitors.conf` layout · primary |
| 2026-08-05 | [010](#chg-010--aux-desk-headset-in-the-chain) | AUX desk headset | 83te | **Ready** | Med | WP AUX · `scripts/chg010-*` |
| 2026-08-05 ~15:05 | [011](#chg-011--viewsonic-edid-refresh) | ViewSonic EDID refresh | 83te | Applied | Low | ViewSonic `@59.95` |
| 2026-08-14 | [012](#chg-012--island-enterprise-browser) | Island Enterprise Browser | 83te | Applied | Med | `island-browser-stable` · flags · hypr tag |
| 2026-08-14 | [013](#chg-013--island-setup) | Island setup | 83te | Applied | Low | `hypr/bindings.conf` Super+Shift+I |

---

# I · Multi Display Config

| CHG | Status |
|-----|--------|
| 001 · 009 · 011 | Applied · live desk = 009 layout + 011 Hz |

---

## CHG-001 — The desk in order

> `01` · Applied · 2026-07-05 · `p3oos` · Low

| | |
|---|---|
| **Objective** | Map three 1080p panels left→center→right to match the physical desk; `GDK_SCALE=1`. |
| **Challenge** | Stock `monitor=,preferred,auto,auto` + `GDK_SCALE,2` ignores desk order and double-scales 1080p. |
| **Paths** | `~/.config/hypr/monitors.conf` |

**Execute**

```bash
cp ~/.config/hypr/monitors.conf ~/.config/hypr/monitors.conf.bak.chg001.$(date +%Y%m%d-%H%M%S)
```

```ini
# ~/.config/hypr/monitors.conf  (p3oos historical baseline — ports may differ)
env = GDK_SCALE,1
monitor = DP-4, 1920x1080@60, 0x0, 1
monitor = DP-3, 1920x1080@60, 1920x0, 1
monitor = DP-2, 1920x1080@60, 3840x0, 1
```

```bash
hyprctl reload && hyprctl configerrors && hyprctl monitors
# expect positions 0x0, 1920x0, 3840x0
```

**Backout**

```bash
cp ~/.config/hypr/monitors.conf.bak.chg001.YYYYMMDD-HHMMSS ~/.config/hypr/monitors.conf
hyprctl reload
# stock: env = GDK_SCALE,2  +  monitor=,preferred,auto,auto
```

---

## CHG-009 — Center monitor swap

> `09` · Applied · 2026-08-05 · `83te` docked · Low  
> Layout/primary current. **Hz superseded by [011](#chg-011--viewsonic-edid-refresh).**

| | |
|---|---|
| **Objective** | Replace center Samsung 1080p with ViewSonic VX3276-QHD; recompute offsets; primary on ViewSonic. |
| **Challenge** | Wider center (2560) invalidates old X offsets; dock renames `DP-N` — use `desc:`. |
| **Paths** | `~/.config/hypr/monitors.conf` · note: `docs/chg009-center-monitor-swap.md` |

**Execute**

```bash
hyprctl monitors   # note desc: + availableModes only
cp ~/.config/hypr/monitors.conf ~/.config/hypr/monitors.conf.bak.chg009.$(date +%Y%m%d-%H%M%S)
```

```ini
env = GDK_SCALE,1
# widths 1920+2560+1920 → 0, 1920, 4480
monitor = desc:Sceptre Tech Inc Sceptre F27, 1920x1080@60, 0x0, 1
monitor = desc:ViewSonic Corporation VX3276-QHD, 2560x1440@59.95, 1920x0, 1
monitor = desc:AOC 27E2UA, 1920x1080@60, 4480x0, 1
monitor = eDP-1, 1920x1200@60, 2560x1440, 1.5
monitor = , preferred, auto, 1
workspace = 1, monitor:desc:ViewSonic Corporation VX3276-QHD, default:true
cursor {
    default_monitor = desc:ViewSonic Corporation VX3276-QHD
}
```

```bash
hyprctl reload && hyprctl configerrors && hyprctl monitors
hyprctl workspacerules
# expect: 0x0, 1920x0, 4480x0, eDP 2560x1440; ViewSonic @59.95
```

**Backout**

```bash
cp ~/.config/hypr/monitors.conf.bak.chg009.YYYYMMDD-HHMMSS ~/.config/hypr/monitors.conf
hyprctl reload
```

---

## CHG-011 — ViewSonic EDID refresh

> `11` · Applied · 2026-08-05 ~15:05 · `83te` · Low  
> Supersedes 009 Hz only. `docs/chg011-viewsonic-edid-refresh.md`

| | |
|---|---|
| **Objective** | Stop ViewSonic **Out of Range**; drive only EDID-listed QHD mode. |
| **Challenge** | Marketing 75 Hz; EDID on this dock path lists only `2560x1440@59.95Hz`. Forcing `@74.93` breaks OSD + post-sleep. **Do not revert packages.** |
| **Paths** | `~/.config/hypr/monitors.conf` · bak `…bak.chg011.20260805-150528` |

**Execute**

```bash
hyprctl monitors   # confirm availableModes includes 2560x1440@59.95Hz only for QHD
cp ~/.config/hypr/monitors.conf ~/.config/hypr/monitors.conf.bak.chg011.$(date +%Y%m%d-%H%M%S)
# set ViewSonic line:
# monitor = desc:ViewSonic Corporation VX3276-QHD, 2560x1440@59.95, 1920x0, 1
hyprctl reload && hyprctl configerrors
hyprctl monitors   # ViewSonic ≈ 2560x1440@59.95
```

**Backout**

```bash
cp ~/.config/hypr/monitors.conf.bak.chg011.YYYYMMDD-HHMMSS ~/.config/hypr/monitors.conf
hyprctl reload
# restores @74.93 → Out of Range on this link
```

---

# II · Fish Terminal Config

| CHG | Status |
|-----|--------|
| 002 · 003 · 005 · 006 | Applied |

---

## CHG-002 — A prompt worth looking at

> `02` · Applied · 2026-07-06 · `p3oos` · `83te` · Low

| | |
|---|---|
| **Objective** | Login shell = fish + Tide v6 Rainbow + `done`; keep bash/Starship available. |
| **Challenge** | Stock Starship is thin for heavy terminal work. |
| **Paths** | `~/.config/fish/` · Alacritty shell (later 003/006) |

**Execute**

```bash
cp -a ~/.config/fish ~/.config/fish.bak.chg002.$(date +%Y%m%d-%H%M%S)
yay -S --noconfirm fisher   # or fisher bootstrap
fish -c 'fisher install ilancosman/tide franciscolourenco/done'
fish -c 'tide configure --auto --style=Rainbow --prompt_colors="16 colors" \
  --show_time="24-hour format" --rainbow_prompt_separators=Angled \
  --powerline_prompt_heads=Slanted --powerline_prompt_tails=Sharp \
  --powerline_prompt_style="Two lines, character and frame" \
  --prompt_connection=Dotted --powerline_right_prompt_frame=Yes \
  --prompt_spacing=Compact --icons="Many icons" --transient=Yes'
chsh -s /usr/bin/fish   # re-login
# keep Omarchy PATH/mise/zoxide in config.fish
getent passwd $USER | cut -d: -f7   # → /usr/bin/fish
```

**Backout**

```bash
rm -rf ~/.config/fish
cp -a ~/.config/fish.bak.chg002.YYYYMMDD-HHMMSS ~/.config/fish
chsh -s /usr/bin/bash
# or: fish -c 'fisher remove ilancosman/tide franciscolourenco/done'
```

---

## CHG-003 — Alacritty startup

> `03` · Applied · 2026-07-06 · Low · extended by 006

| | |
|---|---|
| **Objective** | Super+Return: one-shot sys summary then interactive fish. |
| **Challenge** | Need kernel/net/disk snapshot without typing; must not re-run in same window. |
| **Paths** | `~/.config/alacritty/alacritty.toml` |

**Execute**

```bash
cp ~/.config/alacritty/alacritty.toml ~/.config/alacritty/alacritty.toml.bak.chg003.$(date +%Y%m%d-%H%M%S)
```

```toml
[terminal]
osc52 = "CopyPaste"
shell = { program = "/usr/bin/fish", args = ["-l", "-c", "uname -a && ip -4 -br addr && echo $0 && lsblk -f && fastfetch; exec fish -l"] }
```

*(006 inserts `cd /data/Development/Projects` before `exec fish -l`.)*

**Backout**

```bash
cp ~/.config/alacritty/alacritty.toml.bak.chg003.YYYYMMDD-HHMMSS ~/.config/alacritty/alacritty.toml
# or: shell = { program = "/usr/bin/fish", args = ["-l"] }
```

---

## CHG-005 — Readable paths

> `05` · Applied · 2026-07-08 · Low · needs 002

| | |
|---|---|
| **Objective** | Tide pwd segment readable (black text on blue). |
| **Challenge** | Rainbow stock `brwhite`/`white` on blue is unreadable. |
| **Paths** | fish universals (Tide) |

**Execute**

```bash
fish -c 'set -U tide_pwd_color_anchors black
         set -U tide_pwd_color_dirs black
         set -U tide_pwd_color_truncated_dirs black'
# tide reload if already open
```

**Backout**

```bash
fish -c 'set -U tide_pwd_color_anchors brwhite
         set -U tide_pwd_color_dirs brwhite
         set -U tide_pwd_color_truncated_dirs white'
```

---

## CHG-006 — Land in Projects

> `06` · Applied · 2026-07-08 · Low · needs 003 + 004

| | |
|---|---|
| **Objective** | New Alacritty sessions start in `/data/Development/Projects`. |
| **Challenge** | After 004, terminals still open in `$HOME`. |
| **Paths** | `~/.config/alacritty/alacritty.toml` |

**Execute**

```bash
cp ~/.config/alacritty/alacritty.toml ~/.config/alacritty/alacritty.toml.bak.chg006.$(date +%Y%m%d-%H%M%S)
# in shell args -c string, before exec fish -l:
# … && fastfetch; cd /data/Development/Projects; exec fish -l
```

**Backout**

```bash
# remove: cd /data/Development/Projects;
cp ~/.config/alacritty/alacritty.toml.bak.chg006.YYYYMMDD-HHMMSS ~/.config/alacritty/alacritty.toml
```

---

# III · Disk Partitioning

| CHG | Status |
|-----|--------|
| 004 | Applied · **High** risk |

---

## CHG-004 — Projects on their own disk

> `04` · Applied · 2026-07-06 `p3oos` / 2026-07-09 `83te` · **High**

| | |
|---|---|
| **Objective** | OS on LUKS+btrfs; Projects on second LUKS+XFS at `/data`; symlink `~/Development/Projects`. |
| **Challenge** | Omarchy installer has no separate encrypted data volume; Projects must outlive OS reinstall. |
| **Paths** | GPT/LUKS on `nvme0n1` · `/etc/crypttab` · `/etc/fstab` · `scripts/chg004-*` · real tree `/data/Development/Projects` |

**Layout (reference)**

```
# p3oos: p2 ~350G btrfs / · p3 ~580G XFS /data
# 83te:  p2 200G btrfs OS · p3 ~752G XFS /data
# 83te data LUKS a830ae16-1d9c-4411-9892-f8e8de2ebd3c
# 83te data XFS  5e7b8d54-0931-475b-8163-1b057921d781
/data/Development/Projects/   ← real
~/Development/Projects        → symlink
```

**Execute** (root · live Omarchy · read scripts first)

```bash
cd /data/Development/Projects/socfoundry/omarchy
sudo bash scripts/chg004-partition.sh
sudo bash scripts/chg004-postboot.sh
# reboot
sudo fish scripts/chg004-verify.fish
lsblk -f /dev/nvme0n1
readlink -f ~/Development/Projects   # → /data/Development/Projects
```

**Backout**

- **High risk.** Prefer pre-change safety copies before deleting them.
- Full reverse = restore GPT/LUKS from backup media or reinstall — not a one-liner.
- Soft (migration only wrong): keep p3; fix symlink/mount. **Do not wipe p3** until backups verified elsewhere.

---

# IV · Audio Precedence Config

| CHG | Status |
|-----|--------|
| 007 | Applied |
| 010 | **Ready** — run apply |

---

## CHG-007 — Audio Precedence Config

> `07` · Applied · 2026-07-19 · `83te` · Med · `docs/chg007-audio-precedence-qos.md`

| | |
|---|---|
| **Objective** | Device failover order + always-on Rock EQ for Spotify/Chrome. |
| **Challenge** | BT/USB/built-in fight for default; need stable rank + EQ re-glue. |
| **Paths** | `config/wireplumber/` · `config/audio-eq/` · `bin/audio-precedence-*` · `scripts/chg007-*` |

**Order (007 baseline)** P30i → Lenovo USB-C → built-in → camera  
**(010 current target)** P30i → Lenovo → **AUX** → built-in → camera

**Execute**

```bash
cd /data/Development/Projects/socfoundry/omarchy
bash scripts/chg007-apply.sh
fish scripts/chg007-verify.fish
~/.local/bin/audio-precedence-follow --print
# binds: SUPER+CTRL+E cycle EQ · SUPER+CTRL+SHIFT+E status
```

**Backout**

```bash
bash scripts/chg007-backout.sh          # full
bash scripts/chg007-backout.sh --soft   # EQ + watcher only
```

---

## CHG-010 — AUX desk headset in the chain

> `10` · **Ready** · 2026-08-05 · `83te` · Med · `docs/chg010-aux-desk-headset.md`

| | |
|---|---|
| **Objective** | Permanently plugged AUX ranks after Lenovo, before built-in; fix sof pro-audio map. |
| **Challenge** | AUX is same sof card as speakers: `pro-output-0` = Jack Out (not speakers); `pro-output-2` = speakers; `pro-input-1` = jack mic; `pro-input-10` = dmic. |
| **Paths** | `config/wireplumber/.../50-device-precedence.conf` · `bin/audio-precedence-follow` · `scripts/chg010-*` |

**Priorities** 2500 P30i · 1500 Lenovo · **1000 AUX** · 400 built-in · 50 camera

**Execute**

```bash
cd /data/Development/Projects/socfoundry/omarchy
bash scripts/chg010-apply.sh
fish scripts/chg010-verify.fish
~/.local/bin/audio-precedence-follow --print
amixer -c sofsoundwire cget name='Headphone Jack'
```

**Backout**

```bash
bash scripts/chg007-backout.sh          # prefers *.bak.chg010.* then chg007
bash scripts/chg007-backout.sh --soft
```

---

# V · Screenshot Config

| CHG | Status |
|-----|--------|
| 008 | Applied |

---

## CHG-008 — Screenshot Config

> `08` · Applied · 2026-07-29 · `83te` · Low

| | |
|---|---|
| **Objective** | Screenshots on XFS `/data`, not btrfs root; Super+Shift+S region (Keychron Q4). |
| **Challenge** | Stock writes under `~/Pictures` on OS volume; board has no Print key. |
| **Paths** | `/data/Development/Projects/socfoundry/ss` · fish `OMARCHY_SCREENSHOT_DIR` · Hyprland `env` + bind |

**Execute**

```bash
sudo mkdir -p /data/Development/Projects/socfoundry/ss
sudo chown -R "$USER:$USER" /data/Development/Projects/socfoundry/ss
mkdir -p ~/Pictures
rm -rf ~/Pictures/Screenshots
ln -s /data/Development/Projects/socfoundry/ss ~/Pictures/Screenshots

# fish — use -Ux / -gx once (not -Ua; appends duplicates)
grep -q OMARCHY_SCREENSHOT_DIR ~/.config/fish/config.fish || \
  echo 'set -gx OMARCHY_SCREENSHOT_DIR "/data/Development/Projects/socfoundry/ss"' >> ~/.config/fish/config.fish
fish -c 'set -eU OMARCHY_SCREENSHOT_DIR; set -Ux OMARCHY_SCREENSHOT_DIR /data/Development/Projects/socfoundry/ss'

# Hyprland (personal block — not both with uncommented stock bind)
# env = OMARCHY_SCREENSHOT_DIR,/data/Development/Projects/socfoundry/ss
# bind = SUPER SHIFT, S, exec, omarchy-capture-screenshot
hyprctl reload && hyprctl configerrors
echo $OMARCHY_SCREENSHOT_DIR
findmnt -T /data/Development/Projects/socfoundry/ss
```

**Backout**

```bash
# remove Hyprland env + SUPER SHIFT S; hyprctl reload
# remove set -gx line from config.fish
fish -c 'set -eU OMARCHY_SCREENSHOT_DIR'
rm -f ~/Pictures/Screenshots
# files under …/ss left in place
```

---

# VI · Apps

| CHG | Status |
|-----|--------|
| 012 | Applied · package |
| 013 | Applied · desk setup |

---

## CHG-012 — Island Enterprise Browser

> `12` · Applied · 2026-08-14 · `83te` · Med · `docs/chg012-island-enterprise-browser.md`

| | |
|---|---|
| **Objective** | Install Island Enterprise Browser from the vendor `.deb` as a pacman-tracked package; Wayland flags; Hyprland chromium tag. Leave the default browser alone. |
| **Challenge** | Island ships Debian only. Omarchy is Arch — do not use `dpkg`/`apt`. Skip apt repo, alternatives, AppArmor. |
| **Paths** | `island-browser-stable_150.1.96.29-1_amd64.deb` · `pkg/island-browser-stable/` · `scripts/chg012-*` · `~/.config/island-browser-flags.conf` · `~/.config/hypr/hyprland.conf` |

**Execute**

```bash
cd /data/Development/Projects/socfoundry/omarchy
bash scripts/chg012-apply.sh
fish scripts/chg012-verify.fish
# expect: pacman -Q island-browser-stable · island-browser-stable --version
# Walker: Island · Super+Shift+B stays Chrome (xdg default)
```

**Backout**

```bash
bash scripts/chg012-backout.sh
# restores hypr + flags; sudo pacman -Rns island-browser-stable
# ~/.config/island profile is left in place
```

---

## CHG-013 — Island setup

> `13` · Applied · 2026-08-14 · `83te` · Low · `docs/chg013-island-setup.md`  
> Needs [012](#chg-012--island-enterprise-browser).

| | |
|---|---|
| **Objective** | Desk setup for Island as the work browser: launch-or-focus + incognito binds. Leave Chrome as xdg default. |
| **Challenge** | 012 only installed the package. Need a chord that does not steal Super+Shift+B. Live class is `island-browser`. Enrollment stays operator-only. |
| **Paths** | `~/.config/hypr/bindings.conf` · `scripts/chg013-*` |

**Execute**

```bash
cd /data/Development/Projects/socfoundry/omarchy
bash scripts/chg013-apply.sh
fish scripts/chg013-verify.fish
# Super+Shift+I → Island · Super+Shift+Alt+I incognito
# Super+Shift+B still Chrome
```

**Backout**

```bash
bash scripts/chg013-backout.sh
# package + ~/.config/island stay (use CHG-012 backout to remove the app)
```

---

## Roadmap

| ID | Topic |
|----|--------|
| **014** | Syncthing mesh `/data/Development/Projects` (a8oos · p3oos · 83te) |
| **015+** | Keybinds · workspaces · themes · waybar |

---

<sub>Last applied **013** · staged **010** (`scripts/chg010-apply.sh`) · verbose history: `README.md.bak.verbose.*`</sub>
