# Omarchy

**A field manual for living on Omarchy** — Arch + Hyprland, after CachyOS.

This repository is not the Omarchy distribution. It is the **change ledger** and deploy kit for one operator’s machines: formal sessions, continuous change IDs, scripts that can be re-run or reversed, and enough context that a future self (or a peer) can understand *why* the system looks the way it does.

---

## Prologue

Omarchy is opinionated. That is its virtue and its trap. The stock install is beautiful and coherent — until the desk has three monitors in the wrong order, Projects need a wipe-surviving disk, or Bluetooth headphones lose a priority fight with a USB dongle.

This book records every intentional deviation from stock **as a session**. **Chapters** group work by topic; the **[CHG log](#chg-log)** lists every change ID in date order. Full rules live under that log.

| Rule | Meaning |
|------|---------|
| **One session ↔ one CHG** | Session *N* is always `CHG-00N`. No gaps. |
| **Chapters = topics** | Later work on the same topic **appends** the chapter (see CHG-009 / CHG-011 under I, CHG-010 under VII). |
| **CHG log = chronology** | Date-ordered ledger, separate from chapter numbers. |
| **User space only** | Customize `~/.config/` and this repo. Never edit `~/.local/share/omarchy/` (lost on `omarchy update`). |
| **Reversible by default** | Every CHG ends with backout. Destructive disk work is labeled as such. |

**Primary hosts**

| Host | Role | Notes |
|------|------|--------|
| **p3oos** | Desk tower | Desk dock hosts; Crucial T705 ~1 TB (`nvme0n1`) |
| **83te** | Yoga 7 2-in-1 laptop | Sandisk SN5100S ~1 TB; docked triple-external desk (see CHG-001 / CHG-009 / CHG-011); audio stack (P30i / Lenovo USB-C / AUX / built-in — CHG-007 / CHG-010) |

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

Chapters are **topic books** — a later CHG that extends a topic is appended inside that chapter (not a new chapter number). For a date-ordered list of every change ID, see the [CHG log](#chg-log).

| Chapter | Title | Host focus | Primary CHG | Status |
|---------|-------|------------|-------------|--------|
| [I](#chapter-i--the-desk-in-order) | The desk in order (monitors) | p3oos · 83te | CHG-001 (+ [009](#chg-009--center-monitor-swap) · [011](#chg-011--viewsonic-qhd-refresh-edid-5995-hz)) | Applied |
| [II](#chapter-ii--a-prompt-worth-looking-at) | A prompt worth looking at (fish + Tide) | p3oos, 83te | CHG-002 | Applied |
| [III](#chapter-iii--the-terminal-speaks-first) | The terminal speaks first (Alacritty startup) | both | CHG-003 | Applied |
| [IV](#chapter-iv--projects-on-their-own-disk) | Projects on their own disk (LUKS + XFS `/data`) | p3oos, 83te | CHG-004 | Applied |
| [V](#chapter-v--readable-paths) | Readable paths (Tide pwd contrast) | both | CHG-005 | Applied |
| [VI](#chapter-vi--land-in-projects) | Land in Projects (Alacritty cwd) | both | CHG-006 | Applied |
| [VII](#chapter-vii--sound-that-knows-its-place) | Sound that knows its place (audio) | 83te | CHG-007 (+ [010](#chg-010--aux-desk-headset-in-the-chain)) | Applied / 010 ready |
| [VIII](#chapter-viii--screenshots-on-data) | Screenshots on data | 83te | CHG-008 | Applied |

| Other | |
|-------|--|
| [CHG log](#chg-log) | Chronological change IDs (by date) |
| [Roadmap](#roadmap) | Planned work not yet assigned or in flight |
| [Appendix A](#appendix-a--conventions-for-the-next-chapter) | How to open the next session |
| [Appendix B](#appendix-b--quick-reference) | Command cheat sheet |

---

## CHG log

Every intentional deviation gets a **CHG-00N**. IDs are continuous (no gaps). This table is ordered by **date applied** (then CHG number). Narrative lives in the chapter linked under *Home*.

| Date | CHG | Session | Title | Host | Status | Home |
|------|-----|---------|-------|------|--------|------|
| 2026-07-05 | CHG-001 | 1 | The desk in order (triple monitors) | p3oos | Applied | [Ch I](#chapter-i--the-desk-in-order) |
| 2026-07-06 | CHG-002 | 2 | A prompt worth looking at (fish + Tide) | p3oos, 83te | Applied | [Ch II](#chapter-ii--a-prompt-worth-looking-at) |
| 2026-07-06 | CHG-003 | 3 | The terminal speaks first (Alacritty startup) | — | Applied | [Ch III](#chapter-iii--the-terminal-speaks-first) |
| 2026-07-06 / 07-09 | CHG-004 | 4 | Projects on their own disk (LUKS + XFS `/data`) | p3oos, 83te | Applied | [Ch IV](#chapter-iv--projects-on-their-own-disk) |
| 2026-07-08 | CHG-005 | 5 | Readable paths (Tide pwd contrast) | — | Applied | [Ch V](#chapter-v--readable-paths) |
| 2026-07-08 | CHG-006 | 6 | Land in Projects (Alacritty cwd) | — | Applied | [Ch VI](#chapter-vi--land-in-projects) |
| 2026-07-19 | CHG-007 | 7 | Sound that knows its place (audio precedence + Rock EQ) | 83te | Applied | [Ch VII](#chapter-vii--sound-that-knows-its-place) |
| 2026-07-29 | CHG-008 | 8 | Screenshots on data (XFS route + Keychron Q4 bind) | 83te | Applied | [Ch VIII](#chapter-viii--screenshots-on-data) |
| 2026-08-05 | CHG-009 | 9 | Center monitor swap (Samsung → ViewSonic QHD; refresh later fixed by 011) | 83te | Applied | [Ch I · CHG-009](#chg-009--center-monitor-swap) |
| 2026-08-05 | CHG-010 | 10 | AUX desk headset in the chain | 83te | Ready to apply | [Ch VII · CHG-010](#chg-010--aux-desk-headset-in-the-chain) |
| 2026-08-05 | CHG-011 | 11 | ViewSonic QHD refresh: EDID 59.95 Hz (fix Out of Range) | 83te | Applied | [Ch I · CHG-011](#chg-011--viewsonic-qhd-refresh-edid-5995-hz) |

**Rules**

| Rule | Meaning |
|------|---------|
| **One session ↔ one CHG** | Session *N* is always `CHG-00N`. No gaps, no dual IDs. |
| **Chapters are topics** | A CHG that extends an existing topic **appends that chapter**; it does not open Chapter IX, X, … |
| **This log is chronological** | Sort by date (then CHG). Do not re-order chapters to match dates. |
| **User space only** | Customize `~/.config/` and this repo. Never edit `~/.local/share/omarchy/`. |
| **Reversible by default** | Every CHG ends with backout. Destructive disk work is labeled as such. |


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

- Laptop (**83te**): Session 1 deferred full multi-monitor on this host.
- **p3oos** triple-1080p block above remains the historical baseline for this session.

---

## CHG-009 — Center monitor swap

**Session 9 · CHG-009 · 2026-08-05 · Applied · Host: 83te (docked)**

*Appended to Chapter I. CHG-001 above is the triple-1080p baseline; this session established the Samsung → ViewSonic layout and primary. **Refresh rate was corrected in [CHG-011](#chg-011--viewsonic-qhd-refresh-edid-5995-hz)** (`@74.93` → `@59.95`). See also the [CHG log](#chg-log).*

### Synopsis

Replaced the center **Samsung C27F390** (1080p) with a **ViewSonic VX3276-QHD** (32″ 2560×1440). Because the new panel is wider and taller, every X offset to its right had to be recomputed, the laptop seat under center was recentered, and the ViewSonic was promoted to **primary**. (Session 9 also set refresh to `@74.93` based on marketing/assumed EDID max; that choice was wrong on this dock path — see CHG-011.)

### Why a panel swap breaks the desk

| Failure mode | What happens |
|--------------|--------------|
| Stale `desc:` / port match | New panel falls through to `monitor=,preferred,auto,1` and lands at the far right of the layout |
| Same X offsets as before | Right-hand monitor still starts at `3840` even though center is now 2560 wide → gap or overlap in muscle memory |
| Port hard-coding (`DP-3`) | Dock re-enumeration renames connectors; layout silently targets the wrong cable |
| Ignoring scale / Hz | QHD at 1× is correct (~92 PPI on 32″). **Only use a refresh rate listed in `availableModes`** — marketing “75 Hz” is not enough (see CHG-011) |

### Hardware after swap

| Desk position | Panel | Match key | Mode | Serial |
|---------------|-------|-----------|------|--------|
| Left | Sceptre F27 | `desc:Sceptre Tech Inc Sceptre F27` | 1920×1080@60 · scale 1 | `0x01010101` |
| Center (primary) | ViewSonic VX3276-QHD | `desc:ViewSonic Corporation VX3276-QHD` | **2560×1440@74.93** · scale 1 *(Session 9; **superseded → @59.95 in CHG-011**)* | `YF02607A1509` |
| Right | AOC 27E2UA | `desc:AOC 27E2UA` | 1920×1080@60 · scale 1 | `RLTRAHA010285` |
| Below center | Laptop eDP-1 | `eDP-1` | 1920×1200@60 · scale 1.5 | — |

*Retired center:* Samsung C27F390 · 1920×1080@60 · serial `HCNW207527` (was `desc:Samsung Electric Company C27F390` / earlier port `DP-3`).

### How to swap a monitor (checklist)

Use this whenever any desk panel is replaced:

1. **Plug in and discover**
   ```bash
   hyprctl monitors
   # note: name (DP-*), description (for desc:), availableModes
   # pick native res + highest Hz that actually appears in availableModes (not marketing)
   ```
2. **Map physically** — move the cursor, run `omarchy hyprland monitor focused` on each panel so left/center/right match the room, not cable labels.
3. **Backup**
   ```bash
   cp ~/.config/hypr/monitors.conf ~/.config/hypr/monitors.conf.bak.$(date +%Y%m%d-%H%M%S)
   ```
4. **Edit with `desc:` keys** (never rely on `DP-N` alone after a dock swap):
   - X offset of a monitor = sum of **scaled** widths of everything to its left
   - Y for a row under a taller center = height of the tallest top-row panel (here 1440)
   - Laptop logical width at scale 1.5: `1920 / 1.5 = 1280` → center under middle with `x = middle_x + middle_w/2 - 1280/2`
5. **Promote primary** (optional but recommended for the main work surface):
   ```ini
   workspace = 1, monitor:desc:ViewSonic Corporation VX3276-QHD, default:true
   cursor {
       default_monitor = desc:ViewSonic Corporation VX3276-QHD
   }
   ```
6. **Reload and verify**
   ```bash
   hyprctl reload && hyprctl configerrors && hyprctl monitors
   hyprctl workspacerules   # confirm workspace 1 → ViewSonic, default:true
   ```

### What changed (live config)

**File:** `~/.config/hypr/monitors.conf`

```ini
env = GDK_SCALE,1

# Top row — left → center → right  (widths 1920 + 2560 + 1920 → offsets 0, 1920, 4480)
monitor = desc:Sceptre Tech Inc Sceptre F27, 1920x1080@60, 0x0, 1
monitor = desc:ViewSonic Corporation VX3276-QHD, 2560x1440@74.93, 1920x0, 1
monitor = desc:AOC 27E2UA, 1920x1080@60, 4480x0, 1

# Laptop under ViewSonic: center x = 1920+1280 = 3200; laptop logical w = 1280 → x = 2560
monitor = eDP-1, 1920x1200@60, 2560x1440, 1.5

monitor = , preferred, auto, 1

workspace = 1, monitor:desc:ViewSonic Corporation VX3276-QHD, default:true
cursor {
    default_monitor = desc:ViewSonic Corporation VX3276-QHD
}
```

```
┌─────────────┬──────────────────┬─────────────┐
│  Sceptre    │  ViewSonic QHD   │  AOC        │
│  1920×1080  │  2560×1440@75    │  1920×1080  │
│  (0,0)      │  (1920,0) ★      │  (4480,0)   │
└─────────────┴────────┬─────────┴─────────────┘
                       │  eDP-1 (1.5×)         │
                       │  logical 1280×800     │
                       │  (2560,1440)          │
                       └───────────────────────┘
  ★ primary: workspace 1 default + cursor on login
```

### Optimization choices (ViewSonic as primary)

| Knob | Choice | Rationale |
|------|--------|-----------|
| Resolution | Native `2560×1440` | Sharpest; no GPU scaler |
| Refresh | **`@74.93`** *(Session 9 assumption; **wrong on this link**)* | Intended smoother pointer/scroll; EDID never listed 75 Hz — corrected in **CHG-011** to `@59.95` |
| Scale | `1` | 32″ QHD ≈ 92 PPI — comfortable 1×; avoid fractional |
| Bit depth | 8 (default) | `bitdepth,10` can break screenshot / capture pipelines |
| VRR | off | Desktop-primary; Adaptive Sync left for a later gaming pass |
| Color | sRGB default | Predictable for web/code; no HDR experiment on the daily driver |
| Primary | workspace 1 + `cursor:default_monitor` | New windows / login land on the work surface |

### Verify

- [x] No config errors after `hyprctl reload`
- [x] Positions `0x0`, `1920x0`, `4480x0`, laptop `2560x1440`
- [x] ViewSonic refresh ≈ 74.93 Hz *(Session 9 verify; later broken — see CHG-011)*
- [x] `hyprctl workspacerules` shows workspace 1 → ViewSonic `default:true`
- [ ] Cursor crosses Sceptre → ViewSonic → AOC; down into laptop under center
- [ ] GTK apps not double-scaled (`GDK_SCALE=1`)

### Backout

```bash
# Prefer the pre-swap backup taken at the start of this session
cp ~/.config/hypr/monitors.conf.bak.YYYYMMDD-HHMMSS ~/.config/hypr/monitors.conf
hyprctl reload
```

To re-seat the old Samsung: put its `desc:` line back at `1920x0` with `1920x1080@60`, set AOC to `3840x0`, drop the workspace/cursor primary block (or point it at Samsung), and recompute the laptop `x` for a 1920-wide center.

### Notes

- Port numbers observed on 83te after the swap: Sceptre `DP-6`, ViewSonic `DP-5`, AOC `DP-4`. **Do not hard-code** — `desc:` survives re-dock.
- CHG-001’s port-based triple-1080p block above remains the historical baseline.
- **Current live refresh** for the ViewSonic is documented under **[CHG-011](#chg-011--viewsonic-qhd-refresh-edid-5995-hz)** — do not re-apply `@74.93` from the snippet above.
- Formal change note: `docs/chg009-center-monitor-swap.md`.

---

## CHG-011 — ViewSonic QHD refresh: EDID 59.95 Hz

**Session 11 · CHG-011 · 2026-08-05 · Applied · Host: 83te (docked)**

*Appended to Chapter I. Corrects the refresh-rate choice from [CHG-009](#chg-009--center-monitor-swap) only; layout, primary, and offsets are unchanged. See also the [CHG log](#chg-log).*

### Synopsis

The center **ViewSonic VX3276-QHD** showed **Out of Range** after sleep/updates (flicker after sleep had already started *before* package updates — updates were not the root cause; **no package revert**). Live mode was **`2560×1440@74.93`**, but `hyprctl monitors` **availableModes** list only **`2560×1440@59.95Hz`** for native QHD on this dock/iGPU path. Config forced to the advertised mode.

### Why “Out of Range”

| Failure mode | What happens |
|--------------|--------------|
| Marketing Hz ≠ EDID | Panel sold as “75 Hz class”; EDID on this cable/dock only exposes QHD@~60 |
| Force `@74.93` anyway | GPU sends timings outside the EDID list → OSD **Out of Range** |
| Marginal mode + DPMS | After sleep, handshake often fails or flickers when the mode was never valid |
| Blame package updates | Reboot after pacman/yay made the bad mode more visible; root cause was the mode line |

### Hardware after fix (current desk truth)

| Desk position | Panel | Match key | Mode | Serial |
|---------------|-------|-----------|------|--------|
| Left | Sceptre F27 | `desc:Sceptre Tech Inc Sceptre F27` | 1920×1080@60 · scale 1 | `0x01010101` |
| Center (primary) | ViewSonic VX3276-QHD | `desc:ViewSonic Corporation VX3276-QHD` | **2560×1440@59.95** · scale 1 | `YF02607A1509` |
| Right | AOC 27E2UA | `desc:AOC 27E2UA` | 1920×1080@60 · scale 1 | `RLTRAHA010285` |
| Below center | Laptop eDP-1 | `eDP-1` | 1920×1200@60 · scale 1.5 | — |

### What changed (live config)

**File:** `~/.config/hypr/monitors.conf` — one mode token:

```ini
# CHG-009 (broken on this link)
monitor = desc:ViewSonic Corporation VX3276-QHD, 2560x1440@74.93, 1920x0, 1

# CHG-011 (matches EDID availableModes)
monitor = desc:ViewSonic Corporation VX3276-QHD, 2560x1440@59.95, 1920x0, 1
```

```
┌─────────────┬──────────────────┬─────────────┐
│  Sceptre    │  ViewSonic QHD   │  AOC        │
│  1920×1080  │  2560×1440@60    │  1920×1080  │
│  (0,0)      │  (1920,0) ★      │  (4480,0)   │
└─────────────┴────────┬─────────┴─────────────┘
                       │  eDP-1 (1.5×)         │
                       │  logical 1280×800     │
                       │  (2560,1440)          │
                       └───────────────────────┘
  ★ primary: workspace 1 default + cursor on login
```

### Procedure

1. Confirm EDID list: `hyprctl monitors` → ViewSonic `availableModes` (must include the mode you set).
2. Backup: `cp ~/.config/hypr/monitors.conf ~/.config/hypr/monitors.conf.bak.chg011.$(date +%Y%m%d-%H%M%S)`
3. Set `2560x1440@59.95` (or `@60` if Hyprland accepts the alias).
4. `hyprctl reload && hyprctl configerrors && hyprctl monitors`

### Verify

- [x] No config errors after `hyprctl reload`
- [x] ViewSonic live `2560x1440@59.95100` (matches EDID)
- [x] Positions still `0x0`, `1920x0`, `4480x0`, laptop `2560x1440`
- [ ] OSD no longer shows Out of Range
- [ ] Suspend/resume: panel wakes cleanly without flicker

### Backout

```bash
cp ~/.config/hypr/monitors.conf.bak.chg011.YYYYMMDD-HHMMSS ~/.config/hypr/monitors.conf
hyprctl reload
```

Backout restores `@74.93` and will reintroduce Out of Range on the current dock path — only useful for A/B testing.

### If you want true 75 Hz later

Only when `availableModes` actually lists a ~75 Hz QHD mode. Until then, options are link-side (direct DP, fewer simultaneous high-res outputs, different dock port), not inventing `@74.93` in config. Four heads on Intel iGPU + MST often caps QHD at 60.

### Notes

- Pre-fix backup: `~/.config/hypr/monitors.conf.bak.chg011.20260805-150528` (also `…bak.20260805-150528`).
- Formal change note: `docs/chg011-viewsonic-edid-refresh.md`.
- CHG-009 remains the layout/primary source of truth; this session only corrects Hz.

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

### Device order (as applied in Session 7)

| Priority | Output | Input |
|----------|--------|--------|
| 1 | soundcore P30i (BT A2DP) | P30i mic (HFP only; A2DP has no capture) |
| 2 | Lenovo USB-C In-Ear | Lenovo USB-C mic |
| 3 | Built-in speakers | Built-in dmic |
| last | — | USB camera mic |

> **Current desk order:** see [CHG-010](#chg-010--aux-desk-headset-in-the-chain) below (P30i → Lenovo → AUX → built-in → camera).

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

## CHG-010 — AUX desk headset in the chain

**Session 10 · CHG-010 · 2026-08-05 · Ready to apply · Host: 83te**

*Appended to Chapter VII. CHG-007 above is the original three-device precedence + Rock EQ baseline; this change inserts permanently-plugged desk AUX and corrects the sof pro-audio map. See also the [CHG log](#chg-log).*

### Synopsis

At the docked desk, **Lenovo USB-C** and a **3.5mm AUX headset** are both permanently plugged. USB-C must win when both are present; AUX must beat built-in speakers/mic; the USB camera stays last. CHG-010 also **corrects the sof pro-audio map**: what CHG-007 nicknamed “Built-in Speakers” (`pro-output-0`) is actually **Jack Out** (the AUX path).

### Why another source is not “just another USB stick”

| Device class | How PipeWire sees it | Precedence lever |
|--------------|----------------------|------------------|
| Bluetooth headset | `bluez_output.*` / `bluez_input.*` | High `priority.session` + follower pick |
| USB headset | Own `alsa_card.usb-…` | Match `node.name` / `device.name` |
| **Laptop 3.5mm AUX** | Same sof card as speakers (`sof_sdw`) — **separate pro PCMs** | Enable the right `pro-output-N` / `pro-input-N`, nick + priority |
| Built-in speakers / dmic | Other PCMs on the **same** card | Lower priority; leave enabled as fallback |
| USB camera | Separate USB capture device | Lowest priority; never prefer |

On **83te** the codec line is `hs:rt721 spk:rt721+rt1320`. Under **pro-audio**:

| ALSA PCM | WirePlumber node | Physical jack |
|----------|------------------|---------------|
| `pcm0p` Jack Out | `…pro-output-0` | **AUX / headphones** |
| `pcm1c` Jack In | `…pro-input-1` | **AUX headset mic** |
| `pcm2p` Speaker | `…pro-output-2` | Built-in speakers |
| `pcm10c` DMIC Raw | `…pro-input-10` | Built-in array mic |

`stereo-fallback` has nicer speaker/HP *ports* but **no capture sources**, so this host stays on pro-audio and ranks the PCMs explicitly.

### Device order after CHG-010

| Priority | Output | Input | `priority.session` |
|----------|--------|--------|--------------------|
| 1 | soundcore P30i (BT A2DP) | P30i mic (HFP only) | 2500 |
| 2 | Lenovo USB-C In-Ear | Lenovo USB-C mic | 1500 |
| 3 | **AUX 3.5mm** (`pro-output-0`) | **AUX mic** (`pro-input-1`) | 1000 |
| 4 | Built-in speakers (`pro-output-2`) | Built-in dmic (`pro-input-10`) | 400 |
| last | — | USB camera mic | 50 |

Desk always-on: USB-C + AUX. Walking around: unplug AUX → follower skips Jack Out via `Headphone Jack` sense and falls to speakers.

### How to add another audio I/O (checklist)

Use this whenever you plug in a new headset, DAC, or dongle and want it in the chain:

1. **Discover live nodes**
   ```fish
   wpctl status
   pactl list short sinks
   pactl list short sources
   # For built-in / AUX on this Yoga:
   cat /proc/asound/card*/pcm*/info | less
   amixer -c sofsoundwire cget name='Headphone Jack'
   ```
2. **Classify the device**
   - New **USB** → match `alsa_output.usb-…` / `alsa_input.usb-…` (and often set `device.profile`).
   - New **BT** → `bluez_output.*` / `bluez_input.*` (MAC-specific rules optional).
   - New **jack on the same sof card** → find which `pro-output-N` / `pro-input-N` is Jack vs Speaker vs DMIC; do **not** assume `pro-output-0` is speakers.
3. **Pick a priority band** (leave gaps for future inserts)
   - ~2500 preferred wireless  
   - ~1500 primary wired desk  
   - ~1000 secondary wired desk (AUX)  
   - ~400 built-in last resort  
   - ~50 camera / junk  
4. **Edit repo config** `config/wireplumber/wireplumber.conf.d/50-device-precedence.conf`
   - `update-props` with `priority.session` / `priority.driver` and a clear `node.nick`
   - Disable only the pro nodes you truly never want (HDMI, deepbuffer)
5. **Teach the follower** `bin/audio-precedence-follow` — WirePlumber priorities help defaults, but EQ glue and “skip when jack unplugged” live here. Insert a pick step in the same order as the table.
6. **Apply + verify** (desktop user, not root)
   ```fish
   bash scripts/chg010-apply.sh
   fish scripts/chg010-verify.fish
   ~/.local/bin/audio-precedence-follow --print
   ```
7. **Failover smoke test**
   - Disconnect P30i → expect Lenovo  
   - Unplug Lenovo, keep AUX → expect AUX  
   - Unplug AUX → expect built-in speakers / dmic  
   - Camera must never win while anything better is up  

### What changed (repo)

| Path | Change |
|------|--------|
| `config/wireplumber/…/50-device-precedence.conf` | AUX @1000 on pro-0/1; speakers @400 on pro-2; dmic @400 on pro-10; stop disabling speaker/dmic PCMs |
| `bin/audio-precedence-follow` | Pick order + jack sense (`Headphone Jack` / `Headset Mic Jack`) |
| `scripts/chg010-apply.sh` | Installs updated WP drop-ins + follower (`*.bak.chg010.*`) |
| `scripts/chg010-verify.fish` | Priority compares P30i > Lenovo > AUX > built-in; nick check on pro-0 |
| `docs/chg010-aux-desk-headset.md` | This change’s formal note |
| `docs/chg007-audio-precedence-qos.md` | Baseline stack (updated cross-links) |

Re-run **`scripts/chg010-apply.sh`** after pull — it reinstalls the WirePlumber drop-in and helpers into `~/.config` / `~/.local/bin`.

### Verify

```fish
bash scripts/chg010-apply.sh
fish scripts/chg010-verify.fish
~/.local/bin/audio-precedence-follow --print
# expect aux_headphone_jack=on when 3.5mm is seated
wpctl status   # AUX nick on pro-output-0; Built-in on pro-output-2
```

- [ ] Priorities: 2500 > 1500 > 1000 > 400 > 50  
- [ ] `pro-output-0` nick contains **AUX** (not “Built-in Speakers”)  
- [ ] With P30i + Lenovo + AUX all present: hardware sink is P30i (EQ still default)  
- [ ] P30i off: hardware sink is Lenovo USB-C  
- [ ] P30i + Lenovo off, AUX in: hardware sink is `…pro-output-0`  
- [ ] Default source is never the USB camera when Lenovo/AUX/dmic exist  

### Backout

Prefer CHG-010 backups, then full CHG-007 stack backout if needed.

```fish
# Soft: stop EQ + watcher only
bash scripts/chg007-backout.sh --soft

# Full stack revert (restores newest *.bak.chg010.* / *.bak.chg007.* when present)
bash scripts/chg007-backout.sh
# Or re-apply git history of 50-device-precedence.conf from pre-CHG-010 and re-run apply
```

### Notes

- **USB camera** on this host is capture-only (Sonix); there is no camera “speakers” sink in the chain.  
- Speaker Switch / Headphone Switch under pro-audio may both show `on`; selection is by **which PCM** streams use, not by those mixers alone.  
- Syncthing mesh is still on the [Roadmap](#roadmap) as **CHG-012** (Session 11 took CHG-011 for ViewSonic EDID refresh).

---
# Chapter VIII — Screenshots on data

**Session 8 · CHG-008 · 2026-07-29 · Applied · Host: 83te**

### Synopsis

Route Omarchy’s screenshot pipeline off the btrfs root and onto the wipe-surviving **XFS** volume from Session 4. Set `OMARCHY_SCREENSHOT_DIR` for both fish and Hyprland, and bind **Super+Shift+S** for region capture on a Keychron Q4 (no Print Screen key).

### Why

Stock capture writes under `XDG_PICTURES_DIR` (usually `~/Pictures`) on the OS volume. Screenshots are artifacts that should live with Projects on `/data` (`nvme0n1p3`), not on the LUKS+btrfs root that gets reinstalled or snapshotted away. A 60% board also cannot press the default Omarchy bind (bare `PRINT`).

`omarchy-capture-screenshot` already prefers an explicit override:

```bash
OUTPUT_DIR="${OMARCHY_SCREENSHOT_DIR:-${XDG_PICTURES_DIR:-$HOME/Pictures}}"
```

### Storage target

| Item | Value |
|------|--------|
| Partition | `nvme0n1p3` — LUKS → XFS → `/data` (Session 4) |
| Directory | `/data/Development/Projects/socfoundry/ss/` |
| Engine | `omarchy-capture-screenshot` (grim / slurp / satty) |
| CLI | `omarchy screenshot` · `omarchy capture screenshot` |

Early drafts also mentioned a stray `~/data` under the btrfs home tree (unrelated to the real `/data` mount). That path was inspected and removed if present; do not recreate it.

### What changed

| Layer | Change |
|-------|--------|
| Target dir | `mkdir` + `chown` on `/data/Development/Projects/socfoundry/ss` |
| Fish | `set -gx OMARCHY_SCREENSHOT_DIR "…"` in `~/.config/fish/config.fish` |
| Hyprland env | `env = OMARCHY_SCREENSHOT_DIR,/data/Development/Projects/socfoundry/ss` |
| Keybind | `bind = SUPER SHIFT, S, exec, omarchy-capture-screenshot` |
| Optional XDG | `~/Pictures/Screenshots` → symlink to the same `ss/` tree (fail-safe for non-Omarchy tools) |

**Files (user space only)**

```
~/.config/fish/config.fish          # export OMARCHY_SCREENSHOT_DIR
~/.config/hypr/hyprland.conf        # personal block: env + bind
# preferred long-term homes (if you source them):
#   ~/.config/hypr/envs.conf
#   ~/.config/hypr/bindings.conf    # stock template already has the bind commented
```

### Procedure

```bash
# 1. Target on XFS /data
sudo mkdir -p /data/Development/Projects/socfoundry/ss
sudo chown -R "$USER:$USER" /data/Development/Projects/socfoundry/ss

# 2. Optional XDG-style alias for other tools
mkdir -p ~/Pictures
rm -rf ~/Pictures/Screenshots
ln -s /data/Development/Projects/socfoundry/ss ~/Pictures/Screenshots

# 3. Fish — persistent export (use -x, not -a; -a appends duplicates)
grep -q OMARCHY_SCREENSHOT_DIR ~/.config/fish/config.fish || \
  echo 'set -gx OMARCHY_SCREENSHOT_DIR "/data/Development/Projects/socfoundry/ss"' >> ~/.config/fish/config.fish
fish -c 'set -eU OMARCHY_SCREENSHOT_DIR; set -Ux OMARCHY_SCREENSHOT_DIR /data/Development/Projects/socfoundry/ss'

# 4. Hyprland — personal block at bottom of hyprland.conf (after sourced files)
#    env = OMARCHY_SCREENSHOT_DIR,/data/Development/Projects/socfoundry/ss
#    bind = SUPER SHIFT, S, exec, omarchy-capture-screenshot
# Stock PRINT binding remains in default utilities.conf for full-size boards.

hyprctl reload && hyprctl configerrors
```

Stock Omarchy already documents the same Super+Shift+S line (commented) in `~/.config/hypr/bindings.conf`. Either uncomment there **or** keep the personal block — not both (duplicate binds).

### Verify

```bash
echo $OMARCHY_SCREENSHOT_DIR
# → /data/Development/Projects/socfoundry/ss

omarchy-capture-screenshot
# → /data/Development/Projects/socfoundry/ss/screenshot-YYYY-MM-DD_HH-MM-SS.png

findmnt -T /data/Development/Projects/socfoundry/ss
# → /data on the XFS LUKS volume (nvme0n1p3), not btrfs root
```

- [ ] CLI write lands under `socfoundry/ss/`
- [ ] Super+Shift+S opens region select (slurp → grim → satty)
- [ ] Bare Print still works if the keyboard has that key
- [ ] `hyprctl configerrors` clean
- [ ] Fish universal is a **single** path (no list of duplicates)

Verified on 83te: captures such as `screenshot-2026-07-29_07-52-51.png` and `screenshot-2026-07-29_07-53-44.png` under the XFS path.

### Backout

```bash
# Remove Hyprland env + SUPER SHIFT S lines from ~/.config/hypr/hyprland.conf
# (or restore a pre-change backup), then:
hyprctl reload

# Fish
# delete the set -gx line from config.fish
fish -c 'set -eU OMARCHY_SCREENSHOT_DIR'

# Optional symlink
rm -f ~/Pictures/Screenshots

# Files already on /data/…/ss are left alone; move or delete manually if desired
```

Capture then falls back to `XDG_PICTURES_DIR` / `~/Pictures`.

### Notes

- **Host:** Applied on **83te** (Yoga + Keychron Q4). Same path layout is valid on **p3oos** after Session 4; re-apply env/bind there if the desk board also lacks Print.
- **Fish footgun:** `set -Ua VAR value` *appends*. A mistaken double-run left two identical universal elements. Prefer `set -Ux` (or clear with `set -eU` first). Global `set -gx` in `config.fish` is enough for interactive shells; Hyprland still needs its own `env =` so binds that never start fish still see the directory.
- **Do not edit** `~/.local/share/omarchy/` — the capture binary already honors `OMARCHY_SCREENSHOT_DIR`.

---

## Roadmap

Planned work not yet in the [CHG log](#chg-log). Assign the next free CHG when a session opens.

| Tentative | Topic | Notes |
|-----------|-------|--------|
| CHG-012 | Syncthing mesh for `/data/Development/Projects` (a8oos, p3oos, 83te) | See `socfoundry/syncthing` if present; was roadmap-slotted as 011 before Session 11 took that ID |
| CHG-013+ | Keybindings & daily workflow; workspace strategy; themes; waybar/walker; CachyOS habit diffs | Ideas |

---

## Appendix A — Conventions for the next chapter

When you open Session *N*:

1. Assign **CHG-00N** (next free integer; never skip). Add a row to the **[CHG log](#chg-log)** with date, host, status, and home chapter.
2. If the work **extends an existing topic**, append a `## CHG-00N — …` section under that chapter. Do **not** invent Chapter IX/X only because the session number grew.
3. If the work is a **new topic**, open the next chapter number (IX, X, …) and link it from the table of contents.
4. Write: Synopsis · Why · What changed · Procedure · Verify · Backout.
5. Put scripts under `scripts/chg00N-*` and durable config under `config/`; formal notes under `docs/chg00N-*.md` when useful.
6. Prefer backups named `*.bak.chg00N.<timestamp>`.
7. **Standing order (agents / assistants):** for **every** issue the operator presents in this repo — fix, investigation, or applied config change — open the next CHG in the same session (or immediately after the fix lands). Do not wait to be asked for the ledger update. Update the CHG log, the home chapter section, `docs/chg00N-*.md`, TOC links, and the edition footer. Re-number roadmap “tentative” IDs if they collide with the new free integer.

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

# Audio (83te — Ch VII; CHG-007 / CHG-010)
wpctl status
pactl get-default-sink
pactl get-default-source
audio-eq status
audio-precedence-follow --print
# jack sense (AUX): amixer -c sofsoundwire cget name='Headphone Jack'
# order: P30i → Lenovo USB-C → AUX → built-in → camera

# Screenshots (83te, Session 8)
echo $OMARCHY_SCREENSHOT_DIR
omarchy screenshot          # or: omarchy-capture-screenshot
# Super+Shift+S — region capture (Keychron Q4 / no Print key)
ls /data/Development/Projects/socfoundry/ss | tail
```

---

*End of current edition. Last applied CHG: **011** (ViewSonic EDID refresh, Ch I, 2026-08-05). **CHG-010** (AUX audio, Ch VII) is staged — re-run `scripts/chg010-apply.sh` to land it. See [CHG log](#chg-log).*
