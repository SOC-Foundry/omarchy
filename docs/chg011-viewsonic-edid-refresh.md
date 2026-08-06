# CHG-011 — ViewSonic QHD refresh: EDID 59.95 Hz

> `11` · **Applied** · 2026-08-05 ~15:05 · `83te` (docked)  
> Home: [Ch I · 011](../README.md#chg-011--viewsonic-qhd-refresh-edid-5995-hz) · [log](../README.md#chg-log) · [register](../README.md#chg-register)  
> Supersedes [CHG-009](chg009-center-monitor-swap.md) **Hz only** (`@74.93` → `@59.95`)

---

## Summary

After CHG-009, the center ViewSonic **VX3276-QHD** showed **Out of Range** (and had been flickering after sleep even before package updates). Hyprland was driving **`2560×1440@74.93`**, but the panel’s EDID on this dock path only advertises **`2560×1440@59.95Hz`**. Forced mode to the advertised refresh; no package revert.

## Root cause

| Signal | Observation |
|--------|-------------|
| Symptom | ViewSonic OSD: “Out of Range”; earlier post-sleep flicker |
| Config (CHG-009) | `2560x1440@74.93` (“marketing 75 Hz” / assumed EDID max) |
| `hyprctl monitors` availableModes | **Only** `2560x1440@59.95Hz` for native QHD — no 75 Hz entry |
| Live mode before fix | `2560x1440@74.93000` (outside EDID list) |
| Not the cause | pacman/yay updates (flicker predated reboot; user: do not revert packages) |

Four outputs on the Intel iGPU (eDP + three DisplayPort via dock/MST) often means the link only trains QHD@60 even when the panel is marketed as 75 Hz.

## Hardware after fix

| Desk position | Panel | Match key | Mode |
|---------------|-------|-----------|------|
| Left | Sceptre F27 | `desc:Sceptre Tech Inc Sceptre F27` | 1920×1080@60 · scale 1 |
| Center (primary) | ViewSonic VX3276-QHD | `desc:ViewSonic Corporation VX3276-QHD` | **2560×1440@59.95** · scale 1 |
| Right | AOC 27E2UA | `desc:AOC 27E2UA` | 1920×1080@60 · scale 1 |
| Below center | Laptop eDP-1 | `eDP-1` | 1920×1200@60 · scale 1.5 |

## Config

**File:** `~/.config/hypr/monitors.conf` (single-line change)

```ini
# Before (CHG-009)
monitor = desc:ViewSonic Corporation VX3276-QHD, 2560x1440@74.93, 1920x0, 1

# After (CHG-011)
monitor = desc:ViewSonic Corporation VX3276-QHD, 2560x1440@59.95, 1920x0, 1
```

Workspace 1 primary + `cursor:default_monitor` unchanged.

## Apply

```bash
cp ~/.config/hypr/monitors.conf ~/.config/hypr/monitors.conf.bak.chg011.$(date +%Y%m%d-%H%M%S)
# set ViewSonic line to 2560x1440@59.95
hyprctl reload && hyprctl configerrors
hyprctl monitors | rg -A 20 'ViewSonic|DP-5'
```

## Verify

- [x] No config errors after `hyprctl reload`
- [x] ViewSonic live mode `2560x1440@59.95100` (matches EDID)
- [x] Positions unchanged: `0x0`, `1920x0`, `4480x0`, laptop `2560x1440`
- [ ] OSD no longer shows Out of Range
- [ ] Suspend/resume: panel wakes without flicker (operator check)

## Backout

```bash
# Restore pre-CHG-011 (74.93) only if needed — will reintroduce Out of Range on this link
cp ~/.config/hypr/monitors.conf.bak.chg011.YYYYMMDD-HHMMSS ~/.config/hypr/monitors.conf
# or explicit:
# monitor = desc:ViewSonic Corporation VX3276-QHD, 2560x1440@74.93, 1920x0, 1
hyprctl reload
```

## Notes

Full narrative and checklist updates: **README Chapter I → CHG-011**.  
Layout baseline remains **CHG-009**; only refresh rate is corrected here.
