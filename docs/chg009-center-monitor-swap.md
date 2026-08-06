# CHG-009 — Center monitor swap (Samsung → ViewSonic QHD)

**Session:** 9 · **Home chapter:** [I · CHG-009](../README.md#chg-009--center-monitor-swap)  
**CHG log:** [chronological ledger](../README.md#chg-log)  
**Host:** `83te` (docked)  
**Date:** 2026-08-05  
**Status:** Applied  
**Appends:** Chapter I (Session 1 / CHG-001 triple-1080p baseline) — not a new chapter  
**Superseded (refresh only):** [CHG-011](chg011-viewsonic-edid-refresh.md) sets ViewSonic to `2560×1440@59.95` (EDID); layout/primary from this CHG remain

---

## Summary

Replaced the center **Samsung C27F390** (1920×1080) with a **ViewSonic VX3276-QHD** (32″ 2560×1440). Recomputed X offsets, recentered the laptop under center, and promoted the ViewSonic to **primary** (workspace 1 + `cursor:default_monitor`). Session 9 also set `@74.93`; that refresh choice was wrong on the dock path and was corrected in CHG-011.

## Hardware after swap

| Desk position | Panel | Match key | Mode |
|---------------|-------|-----------|------|
| Left | Sceptre F27 | `desc:Sceptre Tech Inc Sceptre F27` | 1920×1080@60 · scale 1 |
| Center (primary) | ViewSonic VX3276-QHD | `desc:ViewSonic Corporation VX3276-QHD` | **2560×1440@74.93** · scale 1 *(Session 9; live Hz → CHG-011)* |
| Right | AOC 27E2UA | `desc:AOC 27E2UA` | 1920×1080@60 · scale 1 |
| Below center | Laptop eDP-1 | `eDP-1` | 1920×1200@60 · scale 1.5 |

*Retired:* Samsung C27F390 · serial `HCNW207527`.

## Config

**File:** `~/.config/hypr/monitors.conf`

```ini
env = GDK_SCALE,1
monitor = desc:Sceptre Tech Inc Sceptre F27, 1920x1080@60, 0x0, 1
monitor = desc:ViewSonic Corporation VX3276-QHD, 2560x1440@74.93, 1920x0, 1
monitor = desc:AOC 27E2UA, 1920x1080@60, 4480x0, 1
monitor = eDP-1, 1920x1200@60, 2560x1440, 1.5
monitor = , preferred, auto, 1
workspace = 1, monitor:desc:ViewSonic Corporation VX3276-QHD, default:true
cursor {
    default_monitor = desc:ViewSonic Corporation VX3276-QHD
}
```

Offsets: 1920 + 2560 + 1920 → `0`, `1920`, `4480`. Prefer **`desc:`** over `DP-N` after dock re-enumeration.

## Apply

```bash
cp ~/.config/hypr/monitors.conf ~/.config/hypr/monitors.conf.bak.chg009.$(date +%Y%m%d-%H%M%S)
# edit monitors.conf as above
hyprctl reload && hyprctl configerrors && hyprctl monitors
hyprctl workspacerules
```

## Verify

- [x] No config errors  
- [x] Positions `0x0`, `1920x0`, `4480x0`, laptop `2560x1440`  
- [x] ViewSonic ≈ 74.93 Hz  
- [x] Workspace 1 → ViewSonic `default:true`  

## Backout

```bash
cp ~/.config/hypr/monitors.conf.bak.chg009.YYYYMMDD-HHMMSS ~/.config/hypr/monitors.conf
hyprctl reload
```

## Notes

Full narrative, failure modes, and “how to swap a monitor” checklist: **README Chapter I → CHG-009**.
