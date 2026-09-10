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
| Next free | **CHG-019** |
| Reserved | **015** Syncthing (roadmap; not stolen) |

**Live `83te` (2026-09-09)**

| | |
|---|---|
| Audio | **017:** P30i → Lenovo USB-C → built-in speakers/dmic → camera. EQ Rock on `effect_input.eq`. **010** sof map only (`pro-2`/`pro-10` = laptop). Do not re-run `chg010-apply.sh`. |
| USB | **018:** Genesys hub on Type-C port1, own PSU. Camera `3-2.3` · Xbox `3-2.4.1` · Lenovo IEM `3-2.4.3`. Ugreen RJ-45 unused. Anker 13-in-1 stays port0 (desk LAN). **016** = brownout incident. Pioneer DVD parked until a dedicated strip. |

```bash
omarchy debug --no-sudo --print
hyprctl monitors
~/.local/bin/audio-precedence-follow --print
fish /data/Development/Projects/socfoundry/omarchy/scripts/chg018-verify.fish
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

<a id="chg-log"></a>
<a id="chg-register"></a>

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
| 2026-08-05 / 09-09 | [010](#chg-010--aux-desk-headset-in-the-chain) | AUX desk headset | 83te | Applied | Med | sof map kept · AUX pick **superseded by 017** |
| 2026-08-05 ~15:05 | [011](#chg-011--viewsonic-edid-refresh) | ViewSonic EDID refresh | 83te | Applied | Low | ViewSonic `@59.95` |
| 2026-08-14 | [012](#chg-012--island-enterprise-browser) | Island Enterprise Browser | 83te | Applied | Med | `island-browser-stable` · flags · hypr tag |
| 2026-08-14 | [013](#chg-013--island-setup) | Island setup | 83te | Applied | Low | `hypr/bindings.conf` Super+Shift+I |
| 2026-08-27 | [014](#chg-014--snapper-pre-pacman-only-keep-last-2) | Snapper pre-pacman / keep 2 | 83te | Applied | **High** | `docs/chg014-snapper-pacman-policy.md` · `scripts/chg014-*` |
| 2026-09-08 | [016](#chg-016--usbc-hub-power-cycle) | USB-C hub power-cycle | 83te | **Recovered** | Low | USB `2-4`/`3-2` · `docs/chg016-usbc-hub-power-cycle.md` |
| 2026-09-09 | [017](#chg-017--three-tier-audio-failover) | Three-tier audio failover | 83te | Applied | Med | WP precedence · drop AUX from pick |
| 2026-09-09 | [018](#chg-018--second-usbc-hub-as-built) | Second USB-C hub as-built | 83te | Applied | Low | Genesys hub PSU · camera/Xbox/Lenovo · `docs/chg018-*` |

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
| 004 | Applied · **High** · OS on `nvme0n1p2`, Projects on `/data` |
| 014 | Applied · **High** · Snapper pre-pacman, keep 2; 83te OS volume recovered |

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

## CHG-014 — Snapper: pre-pacman only, keep last 2

> `14` · Applied · 2026-08-27 · `83te` · **High** · [docs/chg014-snapper-pacman-policy.md](docs/chg014-snapper-pacman-policy.md)  
> Same disk as [004](#chg-004--projects-on-their-own-disk) (`nvme0n1p2` 200 GiB btrfs root).

| | |
|---|---|
| **Objective** | Snapshot root only immediately before pacman; retain the last 2. Stop hourly timeline snapshots from filling the 200 GiB OS volume. |
| **Challenge** | Native Omarchy intent is `NUMBER_LIMIT=5` + `TIMELINE_CREATE=no`, but 83te ran stock Snapper (`TIMELINE_CREATE=yes`, `NUMBER_LIMIT=50`) with `snapper-timeline.timer` on and `snapper-cleanup.timer` off. ~882 snapshots, disk at 100% (681 MiB free). `du` cannot see snapshot exclusive COW (~70 GiB). Quotas disabled so `SPACE_LIMIT` is a no-op. `snapper delete` of a batch aborts if any ID is missing. |
| **Paths** | `/etc/snapper/configs/root` · `/etc/pacman.d/hooks/05-snapper-pacman-pre.hook` · `/usr/local/sbin/snapper-pacman-pre` · `~/.local/bin/omarchy-snapshot` · `~/.config/omarchy/hooks/post-update.d/snapper-pacman-policy` · `docs/chg014-snapper-pacman-policy.md` · `scripts/chg014-*` |

**Execute**

```bash
cd /data/Development/Projects/socfoundry/omarchy
bash scripts/chg014-apply.sh
sudo bash scripts/chg014-prune.sh          # keep last 2; skip if already pruned
fish scripts/chg014-verify.fish
# df -h /  should be well under 100%
# sudo snapper --no-dbus -c root list  → current + 2
```

**Backout**

```bash
bash scripts/chg014-backout.sh
# restores NUMBER_LIMIT=5 / no timeline / removes hook
# does not undelete snapshots
```

---

# IV · Audio Precedence Config

| CHG | Status |
|-----|--------|
| 007 | Applied |
| 010 | Applied · sof map · AUX pick superseded by 017 |
| 017 | Applied · three-tier failover |

---

## CHG-007 — Audio Precedence Config

> `07` · Applied · 2026-07-19 · `83te` · Med · `docs/chg007-audio-precedence-qos.md`

| | |
|---|---|
| **Objective** | Device failover order + always-on Rock EQ for Spotify/Chrome. |
| **Challenge** | BT/USB/built-in fight for default; need stable rank + EQ re-glue. |
| **Paths** | `config/wireplumber/` · `config/audio-eq/` · `bin/audio-precedence-*` · `scripts/chg007-*` |

**Order (007 / 017 live)** P30i → Lenovo USB-C → built-in → camera  
**(010)** sof map + AUX in chain — **017** dropped AUX from automatic failover

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

> `10` · Applied · 2026-08-05 / 2026-09-09 · `83te` · Med · `docs/chg010-aux-desk-headset.md`  
> **Live failover is [017](#chg-017--three-tier-audio-failover).** 010’s sof map remains; do not re-run `chg010-apply.sh`.

| | |
|---|---|
| **Objective** | Fix sof pro-audio map (`pro-2`/`pro-10` = speakers/dmic). Originally also ranked AUX after Lenovo. |
| **Challenge** | AUX is same sof card as speakers: `pro-output-0` = Jack Out (not speakers); `pro-output-2` = speakers; `pro-input-1` = jack mic; `pro-input-10` = dmic. |
| **Paths** | `config/wireplumber/.../50-device-precedence.conf` · `bin/audio-precedence-follow` · `scripts/chg010-*` |

**Map (still live)** `pro-0/1` jack · `pro-2/10` laptop  
**Pick order** 010 put AUX at 1000 — **017 disabled jack nodes** (P30i → Lenovo → built-in)

**Execute**

```bash
# Do not apply 010 now — it would restore AUX failover.
# Sof map + three-tier pick: scripts/chg017-apply.sh
fish scripts/chg017-verify.fish
```

**Backout**

```bash
bash scripts/chg007-backout.sh          # prefers *.bak.chg010.* then chg007
bash scripts/chg007-backout.sh --soft
```

---

## CHG-017 — Three-tier audio failover

> `17` · Applied · 2026-09-09 · `83te` · Med · [docs/chg017-three-tier-audio-failover.md](docs/chg017-three-tier-audio-failover.md)

| | |
|---|---|
| **Objective** | Failover is P30i → Lenovo USB-C → built-in speakers/dmic. Unplug USB-C → laptop, not 3.5mm AUX. |
| **Challenge** | CHG-010 kept the correct sof map but ranked AUX (jack) above speakers. Jack sense is often on at the desk, so USB-C unplug landed on AUX. |
| **Paths** | `config/wireplumber/.../50-device-precedence.conf` · `bin/audio-precedence-follow` · `scripts/chg017-*` |

**Execute**

```bash
cd /data/Development/Projects/socfoundry/omarchy
bash scripts/chg017-apply.sh
fish scripts/chg017-verify.fish
~/.local/bin/audio-precedence-follow --print
# wpctl status → Built-in Speakers, no AUX Headset
```

**Backout**

```bash
# restore pre-017 WP drop-ins:
#   ~/.config/wireplumber/wireplumber.conf.d.bak.chg017.<ts>
systemctl --user restart wireplumber.service
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

# VII · USB / Peripherals

| CHG | Status |
|-----|--------|
| 016 | **Recovered** · incident |
| 018 | Applied · as-built wiring + PSU |

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

## CHG-016 — USB-C hub power-cycle

> `16` · **Recovered** · 2026-09-08 · `83te` · Low · [docs/chg016-usbc-hub-power-cycle.md](docs/chg016-usbc-hub-power-cycle.md)

| | |
|---|---|
| **Objective** | Find why the new USB-C hub (camera, DVD, Lenovo USB-C headset, Xbox pad) is power-cycling. |
| **Challenge** | Anker USB-C hub was daisy-chained downstream of **both** Ugreen and the new Genesys hub; new/Ugreen were not on dedicated PSUs. USB `EPROTO` (`err = -71`) + nested-hub power-cycle ~every 2 s, 19:01–19:22. No block I/O. Dedicated PSU on both hubs stopped the storm. |
| **Paths** | `usb 2-4` / `usb 3-2` (PCH xHCI `00:14.0`) · Type-C `port1` · `docs/chg016-usbc-hub-power-cycle.md` |

**Execute**

```bash
# Done by operator: dedicated PSU on Ugreen + new hub; Anker USB-C hub
# pulled off that daisy-chain. Storm last power-cycle 19:22:18.
journalctl -k --since '19:22:21' | grep -E 'err = -71|power cycle|I/O error'
# as-built / standing policy: CHG-018
fish scripts/chg018-verify.fish
```

**Backout**

```bash
# Unplug the new hub. Anker dock / Keychron / trackball are on other buses.
```

---

## CHG-018 — Second USB-C hub as-built

> `18` · Applied · 2026-09-09 · `83te` · Low · [docs/chg018-second-usbc-hub-as-built.md](docs/chg018-second-usbc-hub-as-built.md)  
> Incident: [016](#chg-016--usbc-hub-power-cycle).

| | |
|---|---|
| **Objective** | Standing wiring + power for the second (Genesys) USB-C hub: camera, Lenovo USB-C headset, Xbox pad. Own PSU. No extra hub daisy-chain. |
| **Challenge** | Bus-power + Anker USB-C downstream of Ugreen **and** this hub caused 016’s reset storm. DVD still needs a dedicated strip. Ugreen RJ-45 is unused. |
| **Paths** | Yoga Type-C port1 `usb 2-4`/`3-2` · `docs/chg018-second-usbc-hub-as-built.md` · `scripts/chg018-verify.fish` |

**Execute**

```bash
# Hardware: dedicated PSU on Ugreen + Genesys hub.
# Loads on Genesys: camera 3-2.3 · Xbox 3-2.4.1 · Lenovo IEM 3-2.4.3
# Not on this hub: Pioneer DVD (until custom strip)
cd /data/Development/Projects/socfoundry/omarchy
fish scripts/chg018-verify.fish
```

**Backout**

```bash
# Unplug the Genesys hub from Yoga port1. Anker dock stays.
```

---

## Roadmap

| ID | Topic |
|----|--------|
| **015** | Syncthing mesh `/data/Development/Projects` (a8oos · p3oos · 83te) |
| **019+** | Keybinds · workspaces · themes · waybar |

---

<sub>Last applied **018** · audio live **017** · verbose history: `README.md.bak.verbose.*`</sub>
