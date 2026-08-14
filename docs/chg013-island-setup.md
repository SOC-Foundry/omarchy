# CHG-013 — Island setup

> `13` · **Applied** · 2026-08-14 · `83te`  
> Home: [Ch VI · 013](../README.md#chg-013--island-setup)  
> Needs [CHG-012](chg012-island-enterprise-browser.md) (package + Wayland flags).

## Summary

Desk integration after the Island package is installed and the operator has enrolled. Island is the **work** browser; Chrome stays the **xdg default** (`Super+Shift+B`).

## Live facts (83te, 2026-08-14)

| | |
|---|---|
| WM class | `island-browser` |
| Profile | `~/.config/island/` |
| Default browser | `google-chrome.desktop` (unchanged) |
| Hypr tag | CHG-012 already tags Island as `chromium-based-browser` |

Enrollment / tenant login is operator-only (first launch). Do not script credentials.

## Binds

| Chord | Action |
|-------|--------|
| Super+Shift+I | Launch or focus Island |
| Super+Shift+Alt+I | Island incognito |
| Super+Shift+B | Default browser (Chrome) — unchanged |

`Super+Ctrl+I` stays Omarchy idle-lock toggle. Super+Shift+I was unbound.

## Apply

```bash
cd /data/Development/Projects/socfoundry/omarchy
bash scripts/chg013-apply.sh
fish scripts/chg013-verify.fish
```

## Backout

```bash
bash scripts/chg013-backout.sh
```
