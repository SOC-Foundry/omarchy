# CHG-012 — Island Enterprise Browser

> `12` · **Applied** · 2026-08-14 · `83te`  
> Home: [Ch VI · 012](../README.md#chg-012--island-enterprise-browser)

## Summary

Install Island's vendor Linux build (`island-browser-stable_150.1.96.29-1_amd64.deb`) on Omarchy (Arch + Hyprland). Island only ships a Debian package. Convert it to a pacman-tracked package; do **not** install `dpkg`/`apt` or add Island's apt repo.

Default browser stays whatever `xdg-settings` already reports (Chrome on 83te). Island shows up in Walker as **Island**.

## Why not `dpkg -i`

| Path | Why not |
|------|---------|
| `dpkg -i` / `apt` | Debian tools. No package db, no upgrades, wrong libc/paths. |
| `debtap` | Extra converter; noisy and often wrong on Chromium forks. |
| Dump `/opt` by hand | Untracked files; hard backout. |
| **Local PKGBUILD** | Same pattern as `google-chrome` AUR. `pacman -Rns` reverses it. |

## What gets installed

- Package: `island-browser-stable 150.1.96.29-1`
- Tree: `/opt/island/island-browser/`
- Launchers: `/usr/bin/island-browser-stable`, `/usr/bin/island-browser`
- Desktop: `island-browser.desktop` (+ hidden `org.island.Island.desktop` for portals)
- Icons: `hicolor/*/apps/island-browser.png`
- Sandbox: `/opt/island/island-browser/chrome-sandbox` setuid
- User flags: `~/.config/island-browser-flags.conf` (Wayland ozone)
- Hyprland: tag Island as `chromium-based-browser` (tile + opacity)

Skipped from the Debian postinst: `update-alternatives`, AppArmor, apt repo + cron, GNOME default-apps XML patch, `chromemgmt` group.

## Reinstall / bump

1. Drop the new `.deb` in the kit root.
2. Bump `pkgver` + `sha256sums` in `pkg/island-browser-stable/PKGBUILD`.
3. `bash scripts/chg012-apply.sh`

## Backout

```bash
bash scripts/chg012-backout.sh
```

Leaves `~/.config/island` (profile) in place.
