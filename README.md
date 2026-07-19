# Omarchy

**A field manual for living on Omarchy** — Arch + Hyprland, after CachyOS.

This repository is not the Omarchy distribution. It is the **change ledger** and deploy kit for one operator’s machines: formal sessions, continuous change IDs, scripts that can be re-run or reversed, and enough context that a future self (or a peer) can understand *why* the system looks the way it does.

---

## Prologue

Omarchy is opinionated. That is its virtue and its trap. The stock install is beautiful and coherent — until the desk has three monitors in the wrong order, Projects need a wipe-surviving disk, or Bluetooth headphones lose a priority fight with a USB dongle.

This book records every intentional deviation from stock **as a session**. Rules:

| Rule | Meaning |
|------|---------|
| **One session ↔ one CHG** | Session *N* is always `CHG-00N`. No gaps, no dual IDs. |
| **Applied chronology** | Chapters follow the order work landed, not the order it was dreamed up. |
| **User space only** | Customize `~/.config/` and this repo. Never edit `~/.local/share/omarchy/` (lost on `omarchy update`). |
| **Reversible by default** | Every chapter ends with backout. Destructive disk work is labeled as such. |

**Primary hosts**

| Host | Role | Notes |
|------|------|--------|
| **p3oos** | Desk tower | Triple 1080p external monitors; Crucial T705 ~1 TB (`nvme0n1`) |
| **83te** | Yoga 7 2-in-1 laptop | Sandisk SN5100S ~1 TB; audio stack (P30i / Lenovo USB-C) |

**Safe config map**

| Concern | Path |
|---------|------|
| Hyprland | `~/.config/hypr/` |
| Terminal | `~/.config/alacritty/`, fish under `~/.config/fish/` |
| Audio | `~/.config/wireplumber/`, `~/.config/audio-eq/`, `~/.config/pipewire/` |
| This kit | `~/Development/Projects/socfoundry/omarchy/` → `/data/Development/Projects/socfoundry/omarchy/` |

```bash
omarchy commands
omarchy menu keybindings --print
omarchy theme current
omarchy debug --no-sudo --print
```

---

## Table of contents

| Chapter | Session | CHG | Title | Status |
|---------|---------|-----|-------|--------|
| [I](#chapter-i--the-desk-in-order) | 1 | CHG-001 | The desk in order (triple monitors) | Applied |
| [II](#chapter-ii--a-prompt-worth-looking-at) | 2 | CHG-002 | A prompt worth looking at (fish + Tide) | Applied |
| [III](#chapter-iii--the-terminal-speaks-first) | 3 | CHG-003 | The terminal speaks first (Alacritty startup) | Applied |
| [IV](#chapter-iv--projects-on-their-own-disk) | 4 | CHG-004 | Projects on their own disk (LUKS + XFS `/data`) | Applied |
| [V](#chapter-v--readable-paths) | 5 | CHG-005 | Readable paths (Tide pwd contrast) | Applied |
| [VI](#chapter-vi--land-in-projects) | 6 | CHG-006 | Land in Projects (Alacritty cwd) | Applied |
| [VII](#chapter-vii--sound-that-knows-its-place) | 7 | CHG-007 | Sound that knows its place (audio precedence + Rock EQ) | Applied |
| [Roadmap](#roadmap) | 8+ | CHG-008+ | Syncthing mesh, keybindings, waybar, … | Planned |

---

# Chapter I — The desk in order

**Session 1 · CHG-001 · 2026-07-05 · Applied · Host: p3oos**

### Synopsis

Three 27″ 1080p monitors were detected by Hyprland but laid out backwards relative to the physical desk. Explicit positions and `GDK_SCALE=1` fixed spatial muscle memory.

### Hardware

| Desk position | Panel | Port | Resolution | Serial |
|---------------|-------|------|------------|--------|
| Left | Sceptre F27 | `DP-4` | 1920×1080@60 | `0x01010101` |
| Center | Samsung C27F390 | `DP-3` | 1920×1080@60 | `HCNW207527` |
| Right | AOC 27E2UA | `DP-2` | 1920×1080@60 | `RLTRAHA010285` |

### Why

Stock Omarchy uses:

```ini
env = GDK_SCALE,2
monitor=,preferred,auto,auto
```

Auto placement is consistent but **not** desk-aware. Port names (`DP-2`…) are connector IDs, not left-to-right order. `GDK_SCALE,2` is for HiDPI panels; these are plain 1080p.

### What changed

**File:** `~/.config/hypr/monitors.conf`

```ini
# Left → center → right: Sceptre, Samsung, AOC
env = GDK_SCALE,1
monitor = DP-4, 1920x1080@60, 0x0, 1
monitor = DP-3, 1920x1080@60, 1920x0, 1
monitor = DP-2, 1920x1080@60, 3840x0, 1
```

```
┌─────────────┬─────────────┬─────────────┐
│   DP-4      │   DP-3      │   DP-2      │
│  Sceptre    │  Samsung    │  AOC        │
│  (0,0)      │  (1920,0)   │  (3840,0)   │
└─────────────┴─────────────┴─────────────┘
```

### Procedure

1. Discover: `hyprctl monitors`
2. Confirm physical map: move cursor, run `omarchy hyprland monitor focused`
3. Backup: `cp ~/.config/hypr/monitors.conf ~/.config/hypr/monitors.conf.bak.$(date +%Y%m%d-%H%M%S)`
4. Edit positions (X offset = sum of widths to the left)
5. `hyprctl reload && hyprctl configerrors && hyprctl monitors`

### Verify

- [ ] No config errors
- [ ] Positions `0x0`, `1920x0`, `3840x0`
- [ ] Cursor crosses Sceptre → Samsung → AOC
- [ ] GTK apps not double-scaled

### Backout

```bash
cp ~/.config/hypr/monitors.conf.bak.YYYYMMDD-HHMMSS ~/.config/hypr/monitors.conf
hyprctl reload
# or stock:
# env = GDK_SCALE,2
# monitor=,preferred,auto,auto
```

Nuclear: `omarchy refresh hyprland` (resets *all* Hyprland user config).

### Notes

Laptop (83te): monitors deferred — configure later with the same discovery workflow.

---

# Chapter II — A prompt worth looking at

**Session 2 · CHG-002 · 2026-07-06 · Applied · Hosts: p3oos, 83te**

### Synopsis

Replaced the minimal bash+Starship default for daily work with **fish**, **Fisher**, **Tide v6** (Rainbow powerline), and the **done** notification plugin. Fish is the login shell; bash+Starship remain available.

### Why

Omarchy’s Starship line is clean but thin. Tide gives git/status density, command duration, transient history, and desktop pings when long jobs finish in the background — better fit for heavy terminal days.

### What changed

| Item | Value |
|------|--------|
| Login shell | `/usr/bin/fish` (`chsh`) |
| Plugins | `jorgebucaran/fisher`, `ilancosman/tide@v6`, `franciscolourenco/done` |
| Tide | Rainbow, 16 colors, 24h time, angled/slanted/sharp powerline, two-line + frame, dotted connector, compact, many icons, transient |
| Alacritty | `shell = { program = "/usr/bin/fish", args = ["-l"] }` (later extended in Sessions 3 & 6) |
| Backups | `~/.config/fish.bak.*`, `~/.config/starship.toml.bak.*` |

### Procedure (short)

```bash
cp -a ~/.config/fish ~/.config/fish.bak.$(date +%Y%m%d-%H%M%S)
yay -S --noconfirm fisher   # or bootstrap fisher.fish via curl
fish -c 'fisher install ilancosman/tide franciscolourenco/done'
fish -c 'tide configure --auto --style=Rainbow --prompt_colors="16 colors" \
  --show_time="24-hour format" --rainbow_prompt_separators=Angled \
  --powerline_prompt_heads=Slanted --powerline_prompt_tails=Sharp \
  --powerline_prompt_style="Two lines, character and frame" \
  --prompt_connection=Dotted --powerline_right_prompt_frame=Yes \
  --prompt_spacing=Compact --icons="Many icons" --transient=Yes'
chsh -s /usr/bin/fish   # interactive auth; re-login
```

Ensure `~/.config/fish/config.fish` carries Omarchy PATH, mise, zoxide as needed.

### Verify

- [ ] `getent passwd $USER | cut -d: -f7` → `/usr/bin/fish`
- [ ] New Alacritty shows Rainbow Tide (not `~ ❯` Starship)
- [ ] Transient prompt collapses prior lines
- [ ] Explicit `bash` still gets Starship

### Backout

```bash
# Preferred: restore fish tree
rm -rf ~/.config/fish
cp -a ~/.config/fish.bak.YYYYMMDD-HHMMSS ~/.config/fish
chsh -s /usr/bin/bash
# Remove Alacritty shell override or set back to bash
```

Or soft: `fish -c 'fisher remove ilancosman/tide franciscolourenco/done'`.

---

# Chapter III — The terminal speaks first

**Session 3 · CHG-003 · 2026-07-06 · Applied**

### Synopsis

Every new Alacritty window prints a short system summary (`uname`, addresses, `lsblk`, `fastfetch`), then drops into interactive fish+Tide.

### Why

During transition, knowing kernel, network, and disks without typing is worth ~1–2 seconds at launch.

### What changed

**File:** `~/.config/alacritty/alacritty.toml`

```toml
[terminal]
osc52 = "CopyPaste"
shell = { program = "/usr/bin/fish", args = ["-l", "-c", "uname -a && ip -4 -br addr && echo $0 && lsblk -f && fastfetch; exec fish -l"] }
```

*(Session 6 appends `cd /data/Development/Projects` before `exec fish -l`.)*

### Verify

- [ ] Super+Return shows summary then Tide
- [ ] Second command in the same window does **not** re-run the summary
- [ ] Super+Alt+Return tmux path unaffected

### Backout

```bash
cp ~/.config/alacritty/alacritty.toml.bak.* ~/.config/alacritty/alacritty.toml
# or shell args only:
# shell = { program = "/usr/bin/fish", args = ["-l"] }
```

---

# Chapter IV — Projects on their own disk

**Session 4 · CHG-004 · 2026-07-06 (p3oos) / 2026-07-09 (83te) · Applied · Risk: High**

### Synopsis

Split the system NVMe: keep Omarchy on **LUKS+btrfs**, put wipe-surviving work on a second **LUKS+XFS** volume at `/data`. Migrate `~/Development/Projects` and symlink back.

### Why

Omarchy’s installer does not offer a separate encrypted data disk. Projects are the asset that should outlive distro experiments. btrfs stays for OS snapshots/limine; XFS carries the big tree with strong sequential I/O.

### Layout

**p3oos (desk) — Layout A**

```
nvme0n1
├── p1  vfat   ~2 GiB     /boot
├── p2  LUKS   ~350 GiB   btrfs  →  /
└── p3  LUKS   ~580 GiB   XFS    →  /data
```

**83te (laptop) — smaller OS slice**

```
nvme0n1
├── p1  vfat   2 GiB      /boot
├── p2  LUKS   200 GiB    btrfs OS (fs ~185G, LUKS payload ~190G)
└── p3  LUKS   ~752 GiB   XFS /data
```

| Host | data LUKS UUID | data XFS UUID |
|------|----------------|---------------|
| 83te | `a830ae16-1d9c-4411-9892-f8e8de2ebd3c` | `5e7b8d54-0931-475b-8163-1b057921d781` |

**Paths (both hosts after migration)**

```
/data/Development/Projects/     ← real files
~/Development/Projects          → symlink
```

Same LUKS passphrase as root → single unlock prompt. `crypttab` + `fstab` auto-open `/data` at boot.

### Scripts (this repo)

| Script | Role |
|--------|------|
| `scripts/chg004-partition.sh` | Shrink btrfs/LUKS/p2, create p3 |
| `scripts/chg004-resume.sh` | Resume mid-flight with keyfile |
| `scripts/chg004-finish-*.sh` | LUKS/XFS finish variants |
| `scripts/chg004-postboot.sh` | crypttab, fstab, UKI, migrate Projects |
| `scripts/chg004-verify.fish` | Post-reboot checks |

```bash
# Root, live Omarchy session — know your layout constants first
sudo bash scripts/chg004-partition.sh
sudo bash scripts/chg004-postboot.sh
# reboot, then:
sudo fish scripts/chg004-verify.fish
# after confidence:
# rm -rf ~/Projects.chg004.bak ~/Development/Projects.bak.chg004
```

### Verify

```bash
lsblk -f /dev/nvme0n1
mount | grep /data
df -hT / /data
readlink -f ~/Development/Projects   # → /data/Development/Projects
```

### Backout

**High risk.** Prefer restore from pre-change safety copies *before* deleting them. Full reverse means restoring GPT/LUKS layout from backup media or reinstall — not a casual one-liner. Soft path if only migration is wrong: keep p3, fix symlink/mount. Do not wipe p3 until backups are verified elsewhere.

### 83te notes

Tide/fish (Session 2) and Alacritty startup (Sessions 3 & 6) were applied alongside data on the laptop. Monitors left for later (Session 1 workflow).

---

# Chapter V — Readable paths

**Session 5 · CHG-005 · 2026-07-08 · Applied**

### Synopsis

Tide’s pwd segment uses a blue background. Stock Rainbow text (`brwhite`/`white`) was unreadable. Set pwd text colors to **black**.

### What changed

```bash
fish -c 'set -U tide_pwd_color_anchors black
         set -U tide_pwd_color_dirs black
         set -U tide_pwd_color_truncated_dirs black'
# existing session: tide reload
```

### Backout

```bash
fish -c 'set -U tide_pwd_color_anchors brwhite
         set -U tide_pwd_color_dirs brwhite
         set -U tide_pwd_color_truncated_dirs white'
```

---

# Chapter VI — Land in Projects

**Session 6 · CHG-006 · 2026-07-08 · Applied**

### Synopsis

After Session 4, Projects live under `/data`. New terminals still opened in `$HOME`. Append `cd /data/Development/Projects` to the Alacritty startup chain before `exec fish -l`.

### What changed

**File:** `~/.config/alacritty/alacritty.toml` — startup `-c` string ends with:

```text
… && fastfetch; cd /data/Development/Projects; exec fish -l
```

### Backout

Remove `cd /data/Development/Projects;` from the `shell` args (restore Session 3–only chain), or restore `alacritty.toml` backup.

---

# Chapter VII — Sound that knows its place

**Session 7 · CHG-007 · 2026-07-19 · Applied · Host: 83te**

### Synopsis

WirePlumber device precedence so audio fails over cleanly, plus always-on **Rock** EQ for Spotify and Google Chrome. Call capture walks the same device order. LAN already marks Meet/Zoom/Teams **EF (DSCP 46)** — no host nftables in this change.

### Device order

| Priority | Output | Input |
|----------|--------|--------|
| 1 | soundcore P30i (BT A2DP) | P30i mic (HFP only; A2DP has no capture) |
| 2 | Lenovo USB-C In-Ear | Lenovo USB-C mic |
| 3 | Built-in speakers | Built-in dmic |
| last | — | USB camera mic |

### App path

```
Spotify / Chrome  →  effect_input.eq (Rock)  →  best hardware sink
Calls (mic)       →  best available source in the table above
```

`audio-precedence-watch` re-glues EQ output and default source when devices appear or vanish.

### Repo layout

```
omarchy/
├── README.md                          ← this book
├── docs/chg007-audio-precedence-qos.md
├── bin/audio-precedence-{follow,watch}
├── config/
│   ├── audio-eq/{rock,edm}.conf
│   ├── systemd/user/audio-precedence-watch.service
│   └── wireplumber/wireplumber.conf.d/
│       ├── 50-device-precedence.conf
│       ├── 51-bluetooth-quality.conf
│       ├── 52-stream-music-eq.conf
│       └── bluetooth-a2dp-autoconnect.conf
└── scripts/
    ├── chg004-*.sh / chg004-verify.fish
    └── chg007-{apply,verify,backout}.*
```

### Apply / verify (desktop user, not root)

```fish
bash scripts/chg007-apply.sh
fish scripts/chg007-verify.fish
~/.local/bin/audio-precedence-follow --print
```

### Hotkeys

| Binding | Action |
|---------|--------|
| `SUPER+CTRL+E` | Cycle EQ rock → edm → off |
| `SUPER+CTRL+SHIFT+E` | EQ status |

### Backout

```fish
# Full revert (restores newest *.bak.chg007|008|006|005.* when present)
bash scripts/chg007-backout.sh

# Soft: stop EQ + watcher; keep precedence rules
bash scripts/chg007-backout.sh --soft
```

### Verify (healthy path)

- [ ] `filter-chain` + `audio-precedence-watch` active
- [ ] Default sink `effect_input.eq`
- [ ] With P30i: `pw-link` shows EQ → `bluez_output…P30i`
- [ ] Priorities: P30i 2500 > Lenovo 1500 > built-in 400 > camera 50
- [ ] Default source is not the camera when a better mic exists

---

## Roadmap

| Session | CHG | Topic | Status |
|---------|-----|-------|--------|
| 8 | CHG-008 | Syncthing mesh for `/data/Development/Projects` (a8oos, p3oos, 83te) | Planned — see `socfoundry/syncthing` if present |
| 9+ | CHG-009+ | Keybindings & daily workflow; workspace strategy; themes; waybar/walker; CachyOS habit diffs; command cheat sheet | Ideas |

---

## Appendix A — Conventions for the next chapter

When you open Session *N*:

1. Assign **CHG-00N** (next free integer; never skip).
2. Write the chapter with: Synopsis · Why · What changed · Procedure · Verify · Backout.
3. Put scripts under `scripts/chg00N-*` and durable config under `config/`.
4. Link the chapter from the table of contents.
5. Prefer backups named `*.bak.chg00N.<timestamp>`.

---

## Appendix B — Quick reference

```bash
# Omarchy
omarchy commands
omarchy refresh hyprland          # nuclear Hyprland reset (backs up first)
omarchy debug --no-sudo --print

# Displays
hyprctl monitors
omarchy hyprland monitor focused
hyprctl reload && hyprctl configerrors

# Disks / data
lsblk -f
df -hT / /data
readlink -f ~/Development/Projects

# Audio (83te, Session 7)
wpctl status
pactl get-default-sink
pactl get-default-source
audio-eq status
audio-precedence-follow --print
```

---

*End of current edition. Last applied session: **7 (CHG-007)** — audio precedence on 83te, 2026-07-19.*
