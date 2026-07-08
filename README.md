# Omarchy Transition Notes

Personal documentation for the move from **CachyOS** to **Omarchy** — my first tiling window manager setup on Hyprland.

This folder is a living journal. We add entries here as we configure, learn, and customize the system together.

---

## Session 1 — Triple Monitor Layout (2026-07-05)

### Goal

Identify three external monitors and arrange them in the correct physical order (left → center → right).

### Hardware

| Physical position | Monitor | Hyprland port | Resolution | Serial |
|-------------------|---------|---------------|------------|--------|
| Left | Sceptre F27 | `DP-4` | 1920×1080 @ 60 Hz | `0x01010101` |
| Center | Samsung C27F390 | `DP-3` | 1920×1080 @ 60 Hz | `HCNW207527` |
| Right | AOC 27E2UA | `DP-2` | 1920×1080 @ 60 Hz | `RLTRAHA010285` |

All three are 27" 1080p displays, connected horizontally.

### Problem

Omarchy's default monitor config uses auto-placement:

```ini
monitor=,preferred,auto,auto
```

Hyprland detected all three monitors but placed them in the wrong order relative to the physical desk layout. Before the fix, the auto layout was:

```
AOC (DP-2)  →  Samsung (DP-3)  →  Sceptre (DP-4)
   left            center              right
```

The actual desk layout is the reverse of what we wanted on the right side — Sceptre should be left, AOC should be right.

### How to identify monitors

Useful commands for any future monitor work:

```bash
# Full details: port name, model, resolution, position, serial
hyprctl monitors

# Which monitor is the cursor on right now?
omarchy hyprland monitor focused

# Reload config and check for errors after edits
hyprctl reload && hyprctl configerrors
```

**Key idea:** Hyprland port names (`DP-2`, `DP-3`, `DP-4`) are connector IDs — they do not automatically match physical left-to-right order. Use `make`/`model`/`serial` from `hyprctl monitors` to map ports to physical screens, then move the cursor across displays and run `omarchy hyprland monitor focused` to double-check.

### Fix applied

**File:** `~/.config/hypr/monitors.conf`

Replaced auto layout with explicit positions and switched `GDK_SCALE` from `2` (retina default) to `1` (correct for 1080p):

```ini
# Three 27" 1080p monitors — left to right: Sceptre, Samsung, AOC
env = GDK_SCALE,1
monitor = DP-4, 1920x1080@60, 0x0, 1
monitor = DP-3, 1920x1080@60, 1920x0, 1
monitor = DP-2, 1920x1080@60, 3840x0, 1
```

### Resulting layout

```
┌─────────────┬─────────────┬─────────────┐
│   DP-4      │   DP-3      │   DP-2      │
│  Sceptre    │  Samsung    │  AOC        │
│  (0,0)      │  (1920,0)   │  (3840,0)   │
└─────────────┴─────────────┴─────────────┘
```

Position values are the top-left corner of each monitor in the virtual desktop, in pixels. Three 1080p monitors side by side: `0`, `1920`, `3840`.

### Persistence

This setting survives reboot. `~/.config/hypr/monitors.conf` is sourced by `~/.config/hypr/hyprland.conf` on every Hyprland session start.

It will only be overwritten if we run `omarchy refresh hyprland`, which resets Hyprland configs to Omarchy defaults (with backup).

### Omarchy config map (reference)

| What | Where |
|------|-------|
| Main Hyprland config | `~/.config/hypr/hyprland.conf` |
| Monitor layout | `~/.config/hypr/monitors.conf` |
| Keybindings | `~/.config/hypr/bindings.conf` |
| Appearance (gaps, borders) | `~/.config/hypr/looknfeel.conf` |
| Status bar | `~/.config/waybar/` |
| App launcher | `~/.config/walker/` |
| Themes | `~/.config/omarchy/themes/` |

**Safe rule:** edit `~/.config/`, never `~/.local/share/omarchy/` (that directory is managed by `omarchy update`).

---

## Coming up

Topics to cover as the transition continues:

- [ ] Keybindings and daily workflow
- [ ] Workspace strategy across three monitors
- [ ] Themes and appearance
- [x] Terminal prompt (Fisher + Tide for fish shell)
- [x] Data partition (LUKS + XFS `/data` for Projects — CHG-004)
- [ ] Syncthing pool for Projects on `/data` — a8oos, p3oos, kt83teCos (CHG-005, in progress)
- [ ] Launcher and waybar customization
- [ ] Differences from CachyOS habits
- [ ] Useful `omarchy` commands cheat sheet

---

## Quick reference

```bash
omarchy commands                    # list all omarchy commands
omarchy menu keybindings --print    # show current keybindings
omarchy theme current               # current theme
omarchy debug --no-sudo --print     # system debug info
```

---

## Changelog

Formal change record for Omarchy customizations. Each entry includes baseline state, implementation, verification, rollback, and adaptation notes for related setups.

---

### 2026-07-05 — CHG-001: Explicit triple-monitor horizontal layout

| Field | Value |
|-------|-------|
| **Change ID** | `CHG-001` |
| **Date** | 2026-07-05 |
| **Status** | Applied |
| **Risk** | Low |
| **Downtime** | None (Hyprland hot-reloads on save) |
| **Affected file** | `~/.config/hypr/monitors.conf` |
| **Related config** | `~/.config/hypr/hyprland.conf` (sources `monitors.conf`; not modified) |

#### Summary

Replaced Omarchy's default auto monitor placement with explicit per-monitor positions so the virtual desktop matches the physical desk order: **Sceptre (left) → Samsung (center) → AOC (right)**.

Also changed `GDK_SCALE` from `2` to `1` because all three displays are 1080p — the stock `GDK_SCALE,2` setting is intended for retina-class HiDPI panels and is inappropriate for this hardware.

#### Business justification

On first login, mouse movement across the desk did not match screen order. The Sceptre (physically left) was mapped as the rightmost display, and the AOC (physically right) was mapped as the leftmost. This breaks spatial muscle memory and makes multi-monitor window management unreliable during the CachyOS → Omarchy transition.

#### Pre-change baseline (revert target)

**File:** `~/.config/hypr/monitors.conf`

```ini
# Optimized for retina-class 2x displays, like 13" 2.8K, 27" 5K, 32" 6K.
env = GDK_SCALE,2
monitor=,preferred,auto,auto
```

**Observed behavior before change** (`hyprctl monitors`):

| Port | Model | Position | Physical desk |
|------|-------|----------|---------------|
| `DP-2` | AOC 27E2UA | `0x0` | Right |
| `DP-3` | Samsung C27F390 | `1920x0` | Center |
| `DP-4` | Sceptre F27 | `3840x0` | Left |

Auto placement was internally consistent (three 1080p panels in a row) but **left/right were swapped** relative to the physical setup.

#### Post-change state

**File:** `~/.config/hypr/monitors.conf`

```ini
# Three 27" 1080p monitors — left to right: Sceptre, Samsung, AOC
env = GDK_SCALE,1
monitor = DP-4, 1920x1080@60, 0x0, 1
monitor = DP-3, 1920x1080@60, 1920x0, 1
monitor = DP-2, 1920x1080@60, 3840x0, 1
```

**Observed behavior after change** (`hyprctl monitors`):

| Port | Model | Position | Physical desk |
|------|-------|----------|---------------|
| `DP-4` | Sceptre F27 | `0x0` | Left |
| `DP-3` | Samsung C27F390 | `1920x0` | Center |
| `DP-2` | AOC 27E2UA | `3840x0` | Right |

#### Implementation procedure

1. **Discover monitors and map ports to physical screens**

   ```bash
   hyprctl monitors
   ```

   Record `description`, `make`, `model`, `serial`, and current `at XxY` for each port.

2. **Confirm physical mapping interactively**

   Move the cursor to each physical monitor and run:

   ```bash
   omarchy hyprland monitor focused
   ```

   Repeat until every port is mapped to a physical position on the desk.

3. **Back up the current config before editing**

   ```bash
   cp ~/.config/hypr/monitors.conf \
      ~/.config/hypr/monitors.conf.bak.$(date +%Y%m%d-%H%M%S)
   ```

4. **Edit `~/.config/hypr/monitors.conf`**

   - Comment out or remove the `monitor=,preferred,auto,auto` line.
   - Set `env = GDK_SCALE,1` for 1080p (or appropriate scale for your panels).
   - Add one `monitor =` line per display with explicit `PORT`, resolution, position, and scale.

5. **Apply and validate**

   ```bash
   hyprctl reload
   hyprctl configerrors
   hyprctl monitors
   ```

6. **Functional test**

   - Move cursor left → center → right across the desk; verify it follows physical order.
   - Drag a window across all three displays; verify no gaps or overlaps.
   - Reboot or re-login once to confirm persistence (optional but recommended for change closure).

#### Verification checklist

- [ ] `hyprctl configerrors` returns no errors
- [ ] `hyprctl monitors` shows three monitors at `0x0`, `1920x0`, `3840x0`
- [ ] Cursor crosses displays in Sceptre → Samsung → AOC order
- [ ] `GDK_SCALE` is `1` in `monitors.conf` and GTK apps render at expected size
- [ ] Layout persists after reboot

#### Rollback / backout procedure

**Option A — Restore from manual backup (preferred)**

```bash
# List available backups
ls -lt ~/.config/hypr/monitors.conf.bak.*

# Restore the desired backup (replace timestamp with yours)
cp ~/.config/hypr/monitors.conf.bak.YYYYMMDD-HHMMSS \
   ~/.config/hypr/monitors.conf

hyprctl reload
hyprctl configerrors
hyprctl monitors
```

**Option B — Manual revert to Omarchy stock auto layout**

Edit `~/.config/hypr/monitors.conf` and replace the explicit monitor block with:

```ini
env = GDK_SCALE,2
monitor=,preferred,auto,auto
```

Then reload:

```bash
hyprctl reload && hyprctl configerrors
```

This returns to Omarchy defaults but **will restore the incorrect left/right order** for this desk setup.

**Option C — Full Hyprland config refresh (nuclear; resets all Hyprland user configs)**

```bash
omarchy refresh hyprland
```

`omarchy refresh` creates its own timestamped backup before overwriting. Use only if broader Hyprland config is broken — not needed for monitor-only rollback.

**Rollback validation**

After any rollback, confirm:

```bash
hyprctl monitors
omarchy hyprland monitor focused   # test on each physical screen
```

Document the observed layout so you know which state you are in.

#### Risks and side effects

| Risk | Impact | Mitigation |
|------|--------|------------|
| Wrong port name in config | Monitor not positioned correctly or disabled | Cross-check with `hyprctl monitors` before saving |
| Incorrect position math | Gaps or overlapping virtual desktop | Sum widths left-to-right: each 1080p panel adds `1920` to X offset |
| `GDK_SCALE` mismatch | UI too large/small in GTK apps | Use `1` for 1080p, `1.25`–`2` for HiDPI; test a GTK app after change |
| `omarchy refresh hyprland` | Overwrites custom layout | Avoid unless intentional; backups are created automatically |
| Cable swap / GPU port change | Port names (`DP-2` etc.) may remap | Re-run discovery procedure; port names are not guaranteed stable across hardware changes |

**Not affected by this change:** keybindings, themes, waybar, workspaces, window rules.

#### Adapting for a similar but different setup

Use the same procedure; only the `monitor =` lines and position math change.

**1. Different left-to-right order (same three 1080p monitors)**

Identify ports first, then assign X positions left to right in `1920` pixel steps:

```ini
env = GDK_SCALE,1
monitor = <LEFT_PORT>,   1920x1080@60, 0x0,    1
monitor = <CENTER_PORT>, 1920x1080@60, 1920x0, 1
monitor = <RIGHT_PORT>,  1920x1080@60, 3840x0, 1
```

Example — if you wanted AOC left, Samsung center, Sceptre right:

```ini
monitor = DP-2, 1920x1080@60, 0x0, 1
monitor = DP-3, 1920x1080@60, 1920x0, 1
monitor = DP-4, 1920x1080@60, 3840x0, 1
```

**2. Different resolutions in one row**

X position = sum of widths of all monitors to the left.

```ini
# Example: 2560px left + 1920px center + 1920px right
monitor = DP-1, 2560x1440@60, 0x0,    1
monitor = DP-2, 1920x1080@60, 2560x0, 1
monitor = DP-3, 1920x1080@60, 4480x0, 1
```

**3. Two monitors only**

```ini
env = GDK_SCALE,1
monitor = DP-1, 1920x1080@60, 0x0,    1
monitor = DP-2, 1920x1080@60, 1920x0, 1
```

Disable an unused port explicitly if it causes ghost displays:

```ini
monitor = DP-3, disable
```

**4. Stacked layout (one monitor above another)**

Y position = height of monitors above.

```ini
# Samsung on top, Sceptre below (both 1080p)
monitor = DP-3, 1920x1080@60, 0x0,    1
monitor = DP-4, 1920x1080@60, 0x1080, 1
```

**5. Portrait / rotated monitor**

Add `transform` — `1` = 90°, `2` = 180°, `3` = 270°:

```ini
monitor = DP-2, 1920x1080@60, 3840x0, 1, transform, 1
```

Recalculate positions using the *effective* width after rotation.

**6. Laptop + external monitors**

Laptop panel first, externals after. Disable internal display when docked if desired:

```ini
monitor = eDP-1, 1920x1080@60, 0x0,    1
monitor = DP-4,  1920x1080@60, 1920x0, 1
monitor = DP-3,  1920x1080@60, 3840x0, 1
# When docked and lid closed:
# monitor = eDP-1, disable
```

**7. Fractional scaling (1440p or 4K panels)**

```ini
env = GDK_SCALE,1
monitor = DP-1, 2560x1440@144, 0x0, 1.25
```

Use `omarchy hyprland monitor scaling cycle` on the focused display to experiment before committing.

#### Universal workflow (any monitor change)

```
Discover  →  Map physical to port  →  Backup  →  Edit monitors.conf  →  Reload  →  Verify  →  Reboot test
```

Always keep a timestamped backup before editing. Always run `hyprctl configerrors` after reload.

---

### 2026-07-06 — CHG-002: Fisher + Tide fish shell prompt

| Field | Value |
|-------|-------|
| **Change ID** | `CHG-002` |
| **Date** | 2026-07-06 |
| **Status** | Applied |
| **Risk** | Low |
| **Downtime** | None for install; re-login required after `chsh` |
| **Affected paths** | `~/.config/fish/`, `~/.config/fish/config.fish`, `~/.config/alacritty/alacritty.toml` |
| **Related config** | `~/.config/starship.toml` (unchanged — retained for bash/tmux fallback) |
| **Default shell** | `/usr/bin/fish` (via `chsh`; requires interactive auth — see step 5) |
| **Alacritty shell** | `/usr/bin/fish -l` (explicit in alacritty.toml) |

#### Summary

Installed the **Fisher** plugin manager, **Tide v6.2.0** prompt, and the **done** notification plugin for the fish shell. Configured Tide with a Rainbow two-line powerline prompt (angled separators, slanted heads, sharp tails, dotted connection, right-frame, compact spacing, many icons, transient prompt, 24-hour clock).

Sets **fish** as the global login shell so Tide is the default prompt everywhere (terminals, SSH, tmux new sessions). Bash + Starship remain available explicitly via `bash` or the Super+Alt+Return tmux binding.

**Post-deploy fix (2026-07-06):** Initial install left bash as the login shell, so terminals showed Starship (`~ ❯`) instead of Tide. Remediated by:
- `shell = { program = "/usr/bin/fish", args = ["-l"] }` in `~/.config/alacritty/alacritty.toml`
- `~/.config/fish/config.fish` with Omarchy PATH, mise, and zoxide init
- `chsh -s /usr/bin/fish` as a **required** step (needs fingerprint/password at the console)

Alacritty + JetBrainsMono Nerd Font is the correct terminal — no app change needed.

#### Business justification

Omarchy ships Starship on bash, which is clean but minimal. Tide on fish provides a richer, powerline-style prompt with git/status icons, command duration, transient lines, and desktop notifications when long-running commands finish in background terminals — improving daily terminal workflow during the CachyOS → Omarchy transition.

#### Pre-change baseline (revert target)

**Fish config:** `~/.config/fish/` contained only `completions/grok.fish` (Grok CLI completions). No `config.fish`, no `fish_plugins`, no `fish_variables`, no Fisher, no Tide, no done plugin.

**Default shell:** `/usr/bin/bash`

**Bash prompt:** Starship via `~/.local/share/omarchy/default/bash/init`:

```bash
eval "$(starship init bash)"
```

**Starship config:** `~/.config/starship.toml` (Omarchy minimal cyan prompt — unchanged by this change)

**Packages present before change:**

| Package | Version | Notes |
|---------|---------|-------|
| `fish` | 4.7.1-1 | Installed (Omarchy base) |
| `starship` | 1.25.1-1 | Installed (Omarchy default bash prompt) |
| `fisher` | — | Not installed as pacman package |

#### Post-change state

**Installed fish plugins** (`~/.config/fish/fish_plugins`):

```
jorgebucaran/fisher
ilancosman/tide
franciscolourenco/done
```

**Tide version:** 6.2.0

**Tide configuration** (via `tide configure --auto`):

| Setting | Value |
|---------|-------|
| Style | Rainbow |
| Prompt colors | 16 colors |
| Show time | 24-hour format (`%T`) |
| Rainbow separators | Angled |
| Powerline heads | Slanted |
| Powerline tails | Sharp |
| Powerline style | Two lines, character and frame |
| Prompt connection | Dotted (`·`) |
| Right prompt frame | Yes |
| Prompt spacing | Compact |
| Icons | Many icons |
| Transient prompt | Yes |

**Key Tide universal variables** (stored in `~/.config/fish/fish_variables`):

- `tide_left_prompt_items`: `os`, `pwd`, `git`, `newline`, `character`
- `tide_right_prompt_items`: `status`, `cmd_duration`, `context`, `jobs`, `direnv`, … (toolchain icons)
- `tide_prompt_transient_enabled`: `true`
- `tide_right_prompt_frame_enabled`: `true`
- `tide_time_format`: `%T`

**Files added/modified under `~/.config/fish/`:**

| Path | Purpose |
|------|---------|
| `functions/fisher.fish` | Fisher plugin manager |
| `functions/fish_prompt.fish` | Tide prompt (replaces default) |
| `functions/tide.fish`, `functions/tide/` | Tide CLI and subcommands |
| `functions/_tide_*` | Tide prompt item renderers |
| `conf.d/_tide_init.fish` | Tide install/update/uninstall hooks |
| `conf.d/done.fish` | Desktop notification on long commands |
| `completions/fisher.fish`, `completions/tide.fish` | Tab completions |
| `fish_plugins` | Plugin manifest |
| `fish_variables` | Universal variables (Tide config + Fisher metadata) |

**Default shell (post-`chsh`):** `/usr/bin/fish`

```bash
getent passwd $USER | cut -d: -f7   # expect: /usr/bin/fish
```

**Alacritty shell override** (`~/.config/alacritty/alacritty.toml`):

```toml
[terminal]
shell = { program = "/usr/bin/fish", args = ["-l"] }
```

**Fish login init** (`~/.config/fish/config.fish`): Omarchy `PATH`, `mise`, `zoxide`.

**Backups created during deployment:**

| Backup | Path |
|--------|------|
| Fish config | `~/.config/fish.bak.20260706-055228` |
| Starship config | `~/.config/starship.toml.bak.20260706-055228` |

#### Implementation procedure

1. **Back up current fish and starship configs**

   ```bash
   cp -a ~/.config/fish ~/.config/fish.bak.$(date +%Y%m%d-%H%M%S)
   cp -a ~/.config/starship.toml ~/.config/starship.toml.bak.$(date +%Y%m%d-%H%M%S)
   ```

2. **Install Fisher** (system package — requires sudo)

   ```bash
   yay -S --noconfirm fisher
   ```

   If the pacman package is unavailable or sudo is not accessible, bootstrap Fisher directly in fish:

   ```bash
   fish -c 'curl -sL https://raw.githubusercontent.com/jorgebucaran/fisher/main/functions/fisher.fish | source && fisher install jorgebucaran/fisher'
   ```

3. **Install Tide and done plugins**

   ```bash
   fish -c 'fisher install ilancosman/tide franciscolourenco/done'
   ```

4. **Configure Tide (non-interactive)**

   ```bash
   fish -c 'tide configure --auto \
     --style=Rainbow \
     --prompt_colors="16 colors" \
     --show_time="24-hour format" \
     --rainbow_prompt_separators=Angled \
     --powerline_prompt_heads=Slanted \
     --powerline_prompt_tails=Sharp \
     --powerline_prompt_style="Two lines, character and frame" \
     --prompt_connection=Dotted \
     --powerline_right_prompt_frame=Yes \
     --prompt_spacing=Compact \
     --icons="Many icons" \
     --transient=Yes'
   ```

5. **Set fish as global default shell** (required)

   ```bash
   # Confirm fish is an allowed login shell
   grep fish /etc/shells

   # Change default shell (prompts for password or fingerprint)
   chsh -s /usr/bin/fish
   ```

   Log out and back in (or reboot) for `chsh` to take effect. After re-login, all new terminals, SSH sessions, and scripts using `$SHELL` will use fish with Tide.

6. **Configure Alacritty to launch fish** (belt-and-suspenders; ensures Tide even before re-login)

   Add to `~/.config/alacritty/alacritty.toml` under `[terminal]`:

   ```toml
   shell = { program = "/usr/bin/fish", args = ["-l"] }
   ```

7. **Create fish login init** (`~/.config/fish/config.fish`)

   Omarchy PATH and tool activation (mise, zoxide) so fish matches bash convenience.

8. **Verify**

   ```bash
   getent passwd $USER | cut -d: -f7    # /usr/bin/fish
   echo $SHELL                          # /usr/bin/fish (after re-login)
   fish -c 'tide --version'
   fish -c 'cat ~/.config/fish/fish_plugins'
   fish -c 'set -U | grep tide_left_prompt_items'
   ```

   Open a new Alacritty window (Super+Return) and confirm the rainbow two-line powerline prompt renders correctly.

#### Verification checklist

- [ ] `getent passwd $USER | cut -d: -f7` returns `/usr/bin/fish`
- [ ] `echo $SHELL` returns `/usr/bin/fish` (after re-login)
- [ ] `fish -c 'tide --version'` reports `6.x`
- [ ] `~/.config/fish/fish_plugins` lists `jorgebucaran/fisher`, `ilancosman/tide`, `franciscolourenco/done`
- [ ] `fish -c 'functions -q fish_prompt'` succeeds (Tide prompt function exists)
- [ ] New Alacritty window shows rainbow two-line powerline prompt (not `~ ❯` Starship)
- [ ] Transient prompt collapses previous lines after command execution
- [ ] Right prompt shows time in 24-hour format
- [ ] Long-running command (>5s) in unfocused terminal triggers `done` notification
- [ ] Explicit `bash` session still shows Starship prompt
- [ ] `~/.config/starship.toml` unchanged

#### Rollback / backout procedure

**Option A — Restore pre-change fish config from backup (preferred; full revert)**

```bash
# List available fish backups
ls -lt ~/.config/fish.bak.*

# Remove current fish config
rm -rf ~/.config/fish

# Restore the backup (replace timestamp with yours)
cp -a ~/.config/fish.bak.20260706-055228 ~/.config/fish

# Verify bash/starship still works
bash -ic 'echo $STARSHIP_SESSION_KEY' 2>/dev/null || echo "bash prompt OK"
```

This returns fish to the pre-change state (Grok completions only). Bash/Starship are unaffected.

**Option B — Uninstall Tide and done via Fisher (keep Fisher installed)**

```bash
fish -c 'fisher remove ilancosman/tide franciscolourenco/done'
```

Fisher automatically:
- Removes Tide/done files from `~/.config/fish/`
- Erases all `tide_*` universal variables (via `_tide_init_uninstall` hook)
- Restores default fish prompt

Verify:

```bash
fish -c 'functions -q fish_prompt; or echo "default prompt restored"'
fish -c 'set -U | grep tide_'   # should return nothing
```

**Option C — Remove all Fisher plugins including Fisher itself**

```bash
fish -c 'fisher remove ilancosman/tide franciscolourenco/done jorgebucaran/fisher'
```

Then manually clean up if needed:

```bash
rm -f ~/.config/fish/fish_plugins
# Review fish_variables — Fisher/Tide entries should be gone; restore from backup if unsure
```

**Option D — Reconfigure Tide without uninstalling (soft reset)**

To change prompt style without full removal:

```bash
fish -c 'tide configure'          # interactive wizard
# or re-run the --auto command with different flags
```

To restore Omarchy-like minimal prompt in fish without Starship:

```bash
fish -c 'fisher remove ilancosman/tide'
# Then optionally add starship to fish:
fish -c 'starship init fish | source'
# Or add to ~/.config/fish/config.fish:
# starship init fish | source
```

**Option E — Revert global default shell to bash** (required for full CHG-002 backout)

```bash
chsh -s /usr/bin/bash
```

Log out and back in. Bash/Starship resume as the login prompt.

Also remove the Alacritty fish override — delete or comment out the `shell = ...` line in `~/.config/alacritty/alacritty.toml` under `[terminal]`, or Alacritty will still open fish despite bash being the login shell.

**Option F — Remove fisher pacman package (if installed)**

```bash
yay -Rns fisher
```

This removes the system package only; the `~/.config/fish/functions/fisher.fish` plugin copy remains functional until removed via Option C or A.

**Option G — Nuclear: delete entire fish config**

```bash
rm -rf ~/.config/fish
mkdir -p ~/.config/fish/completions
# Restore only what you need, e.g. grok completions from backup:
cp ~/.config/fish.bak.20260706-055228/completions/grok.fish ~/.config/fish/completions/
```

Use only if the config is corrupted and backups are unavailable.

**Rollback validation**

After any rollback, confirm:

```bash
# Fish state
fish -c 'set -q _fisher_plugins; and echo "fisher still installed"; or echo "fisher removed"'
fish -c 'functions -q fish_prompt; and functions fish_prompt | head -3'

# Bash unchanged
bash -ic 'type starship && echo "starship OK"'

# Default shell
getent passwd $USER | cut -d: -f7
```

Document which option was used and the observed prompt in both bash and fish.

#### Risks and side effects

| Risk | Impact | Mitigation |
|------|--------|------------|
| `chsh` requires interactive auth | Automated deploy cannot set login shell | Run `chsh -s /usr/bin/fish` manually, then re-login |
| Alacritty `shell` override persists after `chsh` rollback | Terminals still open fish if override not removed | Remove `shell = ...` from `alacritty.toml` when reverting to bash |
| Tide on development branch | `_tide_init.fish` warns if not on release tag | Pin to release: `fisher install ilancosman/tide@v6` |
| Nerd Font required | Powerline glyphs may render as boxes | Ensure terminal uses a Nerd Font (Omarchy terminals typically do) |
| `done` notifications | May fire for long commands in background terminals | Adjust `__done_min_cmd_duration` in `conf.d/done.fish` or uninstall done |
| Universal variables persist | Tide config survives plugin remove/reinstall | `tide configure` or `fisher remove ilancosman/tide` clears them |
| `fisher update` | May pull breaking Tide changes | Pin versions or review release notes before updating |
| Omarchy update | Unlikely to overwrite `~/.config/fish/` | Fish config is user-owned; safe from `omarchy refresh` |
| Starship overlap | None if shells are separate | Do not add `starship init fish` while Tide is active |

**Not affected by this change:** Hyprland, waybar, keybindings, themes, monitor layout (CHG-001), bash/Starship prompt.

#### Adapting for a similar but different setup

**1. Different Tide style (same install procedure)**

Re-run configure with different flags:

```bash
fish -c 'tide configure --auto --style=Lean --prompt_colors="8 colors"'
```

Or use the interactive wizard: `tide configure`

**2. Fish as default shell on any Omarchy install**

```bash
# Install plugins (steps 2–4 above), then:
chsh -s /usr/bin/fish
# Re-login, then verify:
getent passwd $USER | cut -d: -f7
```

**3. Tide + Starship coexistence (different shells)**

- bash → Starship (stock Omarchy)
- fish → Tide (this change)

No conflict as long as each shell initializes only its own prompt.

**4. Pin plugin versions for stability**

```bash
fish -c 'fisher install ilancosman/tide@v6 franciscolourenco/done@1.21.1'
```

**5. Minimal done notifications**

Edit `~/.config/fish/conf.d/done.fish` or set universal variables:

```bash
fish -c 'set -U __done_min_cmd_duration 30000'  # notify only after 30s
```

**6. Transfer config to another machine**

Copy these paths:

```
~/.config/fish/fish_plugins
~/.config/fish/fish_variables
~/.config/fish/functions/
~/.config/fish/conf.d/
~/.config/fish/completions/
```

Then run `fisher install` on the target to ensure files match the plugin manifest.

#### Universal workflow (any fish prompt change)

```
Backup fish config  →  Install/bootstrap Fisher  →  fisher install plugins  →  tide configure  →  chsh to fish  →  alacritty + config.fish  →  re-login  →  verify
```

Always back up `~/.config/fish/` before plugin changes. `chsh` requires interactive authentication — plan for a re-login before closing the change.

---

### 2026-07-06 — CHG-003: Alacritty startup system summary

| Field | Value |
|-------|-------|
| **Change ID** | `CHG-003` |
| **Date** | 2026-07-06 |
| **Status** | Applied |
| **Risk** | Low |
| **Downtime** | None (new Alacritty windows only) |
| **Affected file** | `~/.config/alacritty/alacritty.toml` |
| **Related config** | CHG-002 (`shell` program already set to fish) |

#### Summary

Configured Alacritty to run a system summary on every new terminal window, then drop into the normal interactive fish + Tide session. Commands run once at launch; SSH, tmux attach, and `fish` subshells are unaffected.

**Amended 2026-07-08 (CHG-007):** startup chain now `cd`s into `/data/Development/Projects` before `exec fish -l` so new terminals land in the XFS Projects tree (CHG-004).

#### Business justification

Provides an at-a-glance health check (kernel, network, block devices, hardware/software summary via fastfetch) each time a terminal opens — useful during the Omarchy transition for confirming environment state without typing the commands manually.

#### Pre-change baseline (revert target)

**File:** `~/.config/alacritty/alacritty.toml`

```toml
[terminal]
osc52 = "CopyPaste"
shell = { program = "/usr/bin/fish", args = ["-l"] }
```

**Behavior:** New Alacritty windows opened directly into an interactive fish login shell with Tide prompt. No automatic command output on launch.

#### Post-change state

**File:** `~/.config/alacritty/alacritty.toml`

```toml
[terminal]
osc52 = "CopyPaste"
shell = { program = "/usr/bin/fish", args = ["-l", "-c", "uname -a && ip -4 -br addr && echo $0 && lsblk -f && fastfetch; exec fish -l"] }
```

**Startup command sequence** (runs in order, then interactive shell):

| # | Command | Purpose |
|---|---------|---------|
| 1 | `uname -a` | Kernel / architecture |
| 2 | `ip -4 -br addr` | IPv4 interfaces (brief) |
| 3 | `echo $0` | Shell name (empty in fish — expected) |
| 4 | `lsblk -f` | Block devices with filesystems |
| 5 | `fastfetch` | Omarchy hardware/software summary |
| 6 | `exec fish -l` | Replace process with interactive fish + Tide |

**Backup created:**

| Backup | Path |
|--------|------|
| Alacritty config | `~/.config/alacritty/alacritty.toml.bak.20260706-060208` |

#### Implementation procedure

1. **Back up current config**

   ```bash
   cp -a ~/.config/alacritty/alacritty.toml \
      ~/.config/alacritty/alacritty.toml.bak.$(date +%Y%m%d-%H%M%S)
   ```

2. **Edit `~/.config/alacritty/alacritty.toml`**

   Under `[terminal]`, replace the `shell` line:

   ```toml
   shell = { program = "/usr/bin/fish", args = ["-l", "-c", "uname -a && ip -4 -br addr && echo $0 && lsblk -f && fastfetch; exec fish -l"] }
   ```

3. **Test without opening a GUI window**

   ```bash
   fish -l -c 'uname -a && ip -4 -br addr && echo $0 && lsblk -f && fastfetch; exec fish -l -c "echo interactive_ok"'
   ```

   Confirm commands run and `interactive_ok` prints at the end.

4. **Apply in GUI**

   Open a new Alacritty window (Super+Return). Startup output should appear, followed by the Tide prompt.

   Alacritty live-reloads config changes; if the old behavior persists, close all Alacritty windows and open a fresh one.

#### Verification checklist

- [ ] New Alacritty window prints `uname -a` output on launch
- [ ] `ip -4 -br addr` shows network interfaces
- [ ] `lsblk -f` shows block device table
- [ ] `fastfetch` renders the Omarchy logo block
- [ ] Tide prompt appears after startup output (interactive session)
- [ ] Second command in the same window does **not** re-run startup (no loop)
- [ ] `fish` opened outside Alacritty does **not** run startup commands

#### Rollback / backout procedure

**Option A — Restore from manual backup (preferred)**

```bash
ls -lt ~/.config/alacritty/alacritty.toml.bak.*

cp ~/.config/alacritty/alacritty.toml.bak.YYYYMMDD-HHMMSS \
   ~/.config/alacritty/alacritty.toml
```

Open a new Alacritty window — should launch directly to Tide with no startup output.

**Option B — Manual revert of `shell` line only**

Edit `~/.config/alacritty/alacritty.toml` and change:

```toml
shell = { program = "/usr/bin/fish", args = ["-l"] }
```

**Option C — Full Alacritty config refresh (nuclear)**

```bash
omarchy refresh config alacritty/alacritty.toml
```

This resets to Omarchy stock Alacritty defaults and **removes** the fish shell override from CHG-002 as well. Re-apply CHG-002/003 afterward if needed.

**Rollback validation**

```bash
grep 'shell' ~/.config/alacritty/alacritty.toml
# expect: args = ["-l"]  (no "-c" startup chain)
```

Open Super+Return — confirm no automatic `fastfetch` on launch.

#### Risks and side effects

| Risk | Impact | Mitigation |
|------|--------|------------|
| Slower terminal open | ~1–3s delay while fastfetch runs | Remove or reorder commands; drop `fastfetch` if too slow |
| `sudo` in startup chain | Would block on password every launch | **Not included** — keep it that way |
| `echo $0` empty in fish | `$0` is a bashism; fish leaves it blank | Expected; use `echo $fish_shell` if shell name is needed |
| `exec fish -l` loop | Infinite re-run of startup | `exec fish -l` without `-c` prevents loop — verified |
| `omarchy refresh alacritty` | Overwrites custom shell settings | Avoid unless intentional; backups created automatically |
| tmux pane in Alacritty | Super+Alt+Return uses `bash -c tmux` — unaffected | Startup only applies to default Super+Return binding |

**Not affected:** fish default shell (CHG-002), Tide prompt, Hyprland, waybar, monitor layout.

#### Adapting for a similar but different setup

**Add commands** — append with `&&` before the semicolon:

```toml
shell = { program = "/usr/bin/fish", args = ["-l", "-c", "uname -a && fastfetch; exec fish -l"] }
```

**Run only fastfetch** (minimal):

```toml
shell = { program = "/usr/bin/fish", args = ["-l", "-c", "fastfetch; exec fish -l"] }
```

**Use bash instead of fish** for startup (not recommended with CHG-002):

```toml
shell = { program = "/usr/bin/bash", args = ["-l", "-c", "fastfetch; exec bash -l"] }
```

**Move startup to fish config** (runs in all fish sessions, not just Alacritty):

Add to `~/.config/fish/config.fish` guarded by `status is-interactive` — only use if you want startup everywhere, not just Alacritty.

#### Universal workflow (any Alacritty startup change)

```
Backup alacritty.toml  →  Edit shell args  →  Test with fish -l -c  →  Open new Alacritty window  →  Verify no loop
```

Always use `exec fish -l` (or `exec bash -l`) after one-shot commands to hand off to an interactive shell.

---

### 2026-07-06 — CHG-004: Split nvme0n1 — btrfs OS + encrypted XFS /data

| Field | Value |
|-------|-------|
| **Change ID** | `CHG-004` |
| **Date** | 2026-07-06 |
| **Status** | **Verified** — closed 2026-07-06 post-reboot |
| **Risk** | High (partition/LUKS resize) |
| **Downtime** | ~2 min live rsync; reboot required to close change |
| **Hardware** | Crucial T705 Gen5 NVMe (`CT1000T705SSD3`, `nvme0n1` ~1 TB) |
| **Layout** | **A** — p2 shrunk to ~350 GiB OS; p3 ~580 GiB data |
| **Affected** | `nvme0n1` GPT, LUKS containers, `/etc/crypttab`, `/etc/fstab`, `~/Development/Projects` |
| **Scripts** | `scripts/chg004-partition.sh`, `scripts/chg004-finish-xfs.sh`, `scripts/chg004-postboot.sh` |
| **Rescue media** | Ventoy USB with Omarchy ISO (available; live shrink used instead) |

#### Summary

Shrunk the existing LUKS+btrfs OS partition (`nvme0n1p2`) to ~350 GiB and carved `nvme0n1p3` (~580 GiB) as a second LUKS-encrypted **XFS** volume mounted at `/data`. Migrated `~/Development/Projects/` (~45 GiB) to XFS and symlinked back so tooling paths stay the same. OS remains btrfs with snapper/limine rollback; pipeline data now lives on XFS.

**Before reboot:** partition work, migration, crypttab/fstab, and `limine-mkinitcpio` are complete. **After reboot:** confirm both LUKS volumes unlock and `/data` auto-mounts.

#### Approved decisions (pre-implementation)

| # | Decision | Value |
|---|----------|-------|
| 1 | Data mount point | `/data` |
| 2 | Unlock at boot | Yes — `crypttab` + `encrypt` hook |
| 3 | Partition sizing | Layout **A**: p2 ~350 GiB OS, p3 ~580 GiB data |
| 4 | LUKS passphrase | Same passphrase as root (single prompt) |
| 5 | Valuable data | `~/Development/Projects/` only (~45 GiB) |
| 6 | Cloud backup | Syncthing LAN mesh — **CHG-005** (replaces planned rclone/GDrive) |
| 7 | Scope | In-place shrink/split/copy — **no OS wipe** |

#### Business justification

Omarchy's installer does not offer custom partition layouts (XFS data disk, separate encryption boundary). Projects are the valuable, wipe-surviving asset during distro/config experiments. Separating `/data` on XFS gives fast migration I/O (observed ~732 MB/s rsync on Gen5 NVMe) while keeping btrfs for OS snapshots and limine rollbacks.

#### Pre-change baseline (revert target)

**Single Linux partition on nvme0n1:**

```
nvme0n1p1  vfat   2 GiB    /boot
nvme0n1p2  LUKS   ~929 GiB → btrfs → / /home /var/log /var/cache/pacman/pkg
```

**Projects:** `~/Development/Projects/` on btrfs (~45 GiB used)  
**No** `/data` mount, **no** `nvme0n1p3`

#### Post-change state (Layout A)

```
nvme0n1
├── p1   vfat        2 GiB     /boot
├── p2   LUKS2      ~350 GiB   btrfs  →  /  /home  /snapper  (Omarchy OS)
└── p3   LUKS2      ~580 GiB   XFS    →  /data
```

| Device | LUKS UUID | FS UUID | Mount |
|--------|-----------|---------|-------|
| p2 `root` | `c2d3de56-b03e-474f-bf6f-49bb3c94ed38` | `e9071bb0-c5ba-41b4-b03c-75250325921f` (btrfs) | `/` |
| p3 `data` | `de19c391-a2b5-4397-927a-aedf806b2ef8` | `99601277-7c65-470d-8bcc-82233083e6e1` (xfs) | `/data` |

**Projects path:**

```
/data/Development/Projects/          ← real files (XFS)
~/Development/Projects             → symlink to /data/Development/Projects
~/Development/Projects.bak.chg004  ← original btrfs copy (can delete after verification)
~/Projects.chg004.bak              ← pre-change rsync safety copy on btrfs
```

**crypttab** (both volumes unlock at boot, same passphrase):

```
data  UUID=de19c391-a2b5-4397-927a-aedf806b2ef8  none  luks
```

**fstab:**

```
UUID=99601277-7c65-470d-8bcc-82233083e6e1  /data  xfs  defaults,noatime  0  0
```

**Observed after migration:**

| Filesystem | Size | Used | Avail |
|------------|------|------|-------|
| btrfs `/` | 330G | 168G | 162G |
| xfs `/data` | 580G | 56G | 524G |

Rsync to XFS: ~732 MB/s (~47 GiB in ~61s on Crucial T705).

#### Execution log (2026-07-06)

| Time (approx) | Step | Result |
|---------------|------|--------|
| Pre | `rsync` → `~/Projects.chg004.bak` | 45 GiB safety copy on btrfs |
| 06:33 | `chg004-partition.sh` steps 1–4 | btrfs→330G, LUKS shrink, p2→352GiB, p3 created |
| 06:34 | Step 5 `mkfs.xfs` | **Failed** — `xfsprogs` not installed on fresh Omarchy |
| 06:34 | `pacman -S xfsprogs` + `chg004-finish-xfs.sh` | XFS formatted on p3, label `data` |
| 06:36 | `chg004-postboot.sh` | crypttab, fstab, `limine-mkinitcpio` (**Y**), rsync, symlink |
| 06:38 | Verification | `/data` mounted xfs 580G; symlink active |

**Lessons learned:**

- Install `xfsprogs` before `chg004-partition.sh` (script now auto-installs if missing).
- On Omarchy, always answer **`Y`** to `limine-mkinitcpio` — stock `mkinitcpio -P` has no presets.
- Live shrink from running OS worked; Ventoy rescue USB was not required.

#### Implementation procedure

1. **Pre-flight backup**

   ```bash
   rsync -a ~/Development/Projects/ ~/Projects.chg004.bak/
   du -sh ~/Development/Projects ~/Projects.chg004.bak
   ```

2. **Install xfsprogs** (required; was missing on fresh Omarchy)

   ```bash
   sudo pacman -S --noconfirm xfsprogs
   ```

3. **Shrink p2 + create p3** (live system — sudo + LUKS passphrase)

   ```bash
   cd ~/Development/Projects/socfoundry/omarchy
   sudo bash scripts/chg004-partition.sh
   ```

   Script steps: btrfs resize 330G → LUKS shrink → parted resizepart 2 to 352GiB → mkpart 3 → luksFormat p3.

   If `mkfs.xfs: command not found`, run:

   ```bash
   sudo bash scripts/chg004-finish-xfs.sh
   ```

4. **Post-boot configuration**

   ```bash
   sudo bash scripts/chg004-postboot.sh
   ```

   When prompted for `limine-mkinitcpio`, answer **`Y`** — Omarchy uses Limine UKI, not stock mkinitcpio presets.

5. **Reboot and verify dual LUKS unlock** ✅ (2026-07-06 ~06:45)

   ```bash
   sudo reboot
   ```

   At boot: enter LUKS passphrase once — both `root` and `data` should unlock (same passphrase). Plymouth may show a single prompt for all `crypttab` devices.

   **Post-reboot checks:**

   ```bash
   lsblk -f /dev/nvme0n1
   mount | grep /data
   df -hT / /data
   readlink -f ~/Development/Projects
   cd ~/Development/Projects/socfoundry/omarchy && git status
   ```

6. **Cleanup (after reboot verification — reclaims ~90 GiB on btrfs)**

   ```bash
   rm -rf ~/Projects.chg004.bak ~/Development/Projects.bak.chg004
   ```

   Only delete after confirming Projects work from XFS post-reboot.

#### Verification checklist

**Pre-reboot (completed 2026-07-06 ~06:38):**

- [x] `lsblk -f` shows `nvme0n1p2` (btrfs) and `nvme0n1p3` (xfs, label `data`)
- [x] `df -hT /data` shows xfs ~580G (~56G used after migration)
- [x] `readlink -f ~/Development/Projects` → `/data/Development/Projects`
- [x] `limine-mkinitcpio` completed; UKI updated at `/boot/EFI/Linux/omarchy_linux.efi`
- [x] `/etc/fstab` contains XFS UUID for `/data`
- [x] Safety backups exist: `~/Projects.chg004.bak` + `~/Development/Projects.bak.chg004` (45G each)

**Post-reboot (verified 2026-07-06 ~06:45):**

- [x] LUKS unlock at boot succeeds for both volumes (`root` + `data` mappers active)
- [x] `/data` mounts automatically (no manual `cryptsetup open`)
- [x] `~/Development/Projects` accessible via symlink; contents on XFS
- [x] `limine` boot menu / snapper rollback still works (snapshots 0–5; UKI present)
- [ ] Optional: delete `.bak` copies after 24h confidence period (~90 GiB reclaim)

#### Rollback / backout procedure

**⚠️ Do not delete `~/Projects.chg004.bak` or `~/Development/Projects.bak.chg004` until post-reboot verification passes.**

**⚠️ Full partition merge rollback is destructive. Prefer data-only revert from backups if Projects are the issue.**

**Option A — Data-only revert (keep partition layout)**

```bash
sudo rsync -aHAX /data/Development/Projects/ ~/Development/Projects.restored/
# remove symlink, restore from btrfs backup copy
```

**Option B — Remove /data mount (keep p3 unused)**

```bash
# Comment out data line in /etc/crypttab and /data line in /etc/fstab
sudo limine-mkinitcpio
sudo reboot
```

Projects symlink must point back to a btrfs path.

**Option C — Full partition merge (nuclear; requires rescue USB)**

Boot Ventoy/Omarchy ISO. Backup `/data` contents externally. Delete p3, expand p2, resize LUKS+btrfs upward. Only attempt with full backups and rescue environment experience.

**Option D — Restore Projects from safety backup**

```bash
rm ~/Development/Projects          # if symlink
cp -a ~/Projects.chg004.bak ~/Development/Projects
```

#### Risks and side effects

| Risk | Impact | Mitigation |
|------|--------|------------|
| Live root shrink | Boot failure if interrupted | `~/Projects.chg004.bak`; snapper snapshots on btrfs |
| btrfs at 51% after backup copies | Temporary space pressure | Delete `.bak` copies after verification |
| Missing `xfsprogs` | Partition created, no filesystem | `chg004-finish-xfs.sh` |
| Skipping `limine-mkinitcpio` | `/data` not unlocked at boot | Always answer `Y` on Omarchy |
| Symlinked Projects | Tools with hardcoded btrfs paths | Use `$HOME/Development/Projects` or `/data/...` |
| GDrive backup | Not configured in this change | Planned as follow-up change |

**Not affected:** Hyprland monitors (CHG-001), fish/Tide (CHG-002), Alacritty startup (CHG-003), Windows on `nvme1n1`.

#### Adapting for a similar but different setup

**Different data size:** adjust `BTRFS_TARGET`, `P2_END_GIB`, and `P3_START_GIB` in `chg004-partition.sh`.

**Separate passphrase for /data:** use different passphrase at `luksFormat` for p3; boot will prompt twice (or configure keyfile in crypttab).

**Rescue USB instead of live shrink:** boot Ventoy ISO, unlock p2, mount btrfs `@` subvolume, run same script logic from live environment.

#### Universal workflow (any partition split)

```
Backup Projects  →  install xfsprogs  →  shrink btrfs/LUKS/p2  →  create LUKS+XFS p3  →  crypttab/fstab  →  limine-mkinitcpio  →  migrate + symlink  →  reboot verify  →  cleanup .bak
```

---

### 2026-07-08 — CHG-006: Tide pwd segment text color (readability)

| Field | Value |
|-------|-------|
| **Change ID** | `CHG-006` |
| **Date** | 2026-07-08 |
| **Status** | Applied |
| **Risk** | Low |
| **Downtime** | None (new fish sessions or `tide reload`) |
| **Affected file** | `~/.config/fish/fish_variables` |
| **Related config** | CHG-002 (Fisher + Tide Rainbow prompt) |

#### Summary

The Tide **pwd** (current directory) segment uses a blue background (`tide_pwd_bg_color: blue`). Stock Rainbow 16-color settings used bright white text (`brwhite` / `white`), which was hard to read on that blue block. Text colors were changed to **black** for anchors, directory names, and truncated path segments.

#### Pre-change baseline (revert target)

| Variable | Value |
|----------|-------|
| `tide_pwd_color_anchors` | `brwhite` |
| `tide_pwd_color_dirs` | `brwhite` |
| `tide_pwd_color_truncated_dirs` | `white` |

#### Post-change state

| Variable | Value |
|----------|-------|
| `tide_pwd_color_anchors` | `black` |
| `tide_pwd_color_dirs` | `black` |
| `tide_pwd_color_truncated_dirs` | `black` |

`tide_pwd_bg_color` remains `blue` (unchanged).

#### Implementation procedure

```bash
fish -c 'set -U tide_pwd_color_anchors black; set -U tide_pwd_color_dirs black; set -U tide_pwd_color_truncated_dirs black'
```

Reload in an existing session: `tide reload`. Or open a new terminal.

#### Verification checklist

- [x] `fish -c 'set -U | grep tide_pwd_color'` shows all three variables set to `black`
- [x] New Alacritty window shows black path text on the blue pwd segment

#### Rollback

Restore stock Rainbow 16-color pwd text:

```bash
fish -c 'set -U tide_pwd_color_anchors brwhite; set -U tide_pwd_color_dirs brwhite; set -U tide_pwd_color_truncated_dirs white'
```

#### Notes

- `purple` was tried first as a darker alternative to white; contrast was still insufficient — **black** confirmed readable.
- Not affected: other Tide segments (git, os, time, etc.), bash/Starship, Hyprland.

---

### 2026-07-08 — CHG-007: Alacritty startup cwd → `/data/Development/Projects`

| Field | Value |
|-------|-------|
| **Change ID** | `CHG-007` |
| **Date** | 2026-07-08 |
| **Status** | Applied |
| **Risk** | Low |
| **Downtime** | None (new Alacritty windows only) |
| **Affected file** | `~/.config/alacritty/alacritty.toml` |
| **Related config** | CHG-003 (startup chain), CHG-004 (`/data` Projects mount) |

#### Summary

After the CHG-004 migration, Projects live at `/data/Development/Projects` (symlinked from `~/Development/Projects`). New Alacritty windows still opened in `$HOME`. Appended `cd /data/Development/Projects` to the existing CHG-003 startup command chain, immediately before `exec fish -l`.

#### Pre-change baseline (revert target)

```toml
shell = { program = "/usr/bin/fish", args = ["-l", "-c", "uname -a && ip -4 -br addr && echo $0 && lsblk -f && fastfetch; exec fish -l"] }
```

**Behavior:** Startup summary runs, then interactive fish opens in `$HOME` (`/home/kthompson`).

#### Post-change state

```toml
shell = { program = "/usr/bin/fish", args = ["-l", "-c", "uname -a && ip -4 -br addr && echo $0 && lsblk -f && fastfetch; cd /data/Development/Projects; exec fish -l"] }
```

**Startup command sequence** (CHG-003 commands, then):

| # | Command | Purpose |
|---|---------|---------|
| 7 | `cd /data/Development/Projects` | Land in XFS Projects tree |
| 8 | `exec fish -l` | Interactive fish + Tide |

#### Implementation procedure

Edit `~/.config/alacritty/alacritty.toml` — add `cd /data/Development/Projects;` before `exec fish -l` in the `shell` args string (see post-change state above).

**Test without GUI:**

```bash
fish -l -c 'uname -a >/dev/null; cd /data/Development/Projects; exec fish -l -c "pwd -P"'
# expect: /data/Development/Projects
```

#### Verification checklist

- [x] `grep cd /data ~/.config/alacritty/alacritty.toml` shows the `cd` in the startup chain
- [x] New Alacritty window Tide prompt shows cwd under `/data/Development/Projects`
- [ ] `fish` or SSH sessions opened outside Alacritty still start in `$HOME` (unchanged — by design)

#### Rollback

Remove `cd /data/Development/Projects;` from the `shell` args string (restore CHG-003-only chain).

#### Notes

- **Rejected approach:** `cd` in `~/.config/fish/config.fish` via `status is-interactive` / `status is-login` — fish has not marked the session interactive yet while `config.fish` loads, so the `cd` did not run reliably. Appending to the Alacritty startup chain is simpler and only affects Super+Return terminals.
- **Canonical Projects path:** `/data/Development/Projects/` (real files on XFS). `~/Development/Projects` remains a symlink for tooling compatibility.
- **CHG-004 cleanup pending:** `~/Projects.chg004.bak` and `~/Development/Projects.bak.chg004` (~90 GiB btrfs copies) can be deleted once confident — see CHG-004 step 6.

---

*Next changelog entry: CHG-005 — Syncthing pool for `/data/Development/Projects` across a8oos, p3oos, kt83teCos (in progress — see `socfoundry/syncthing`)*

*CHG-004 closed 2026-07-06 after successful post-reboot verification.*