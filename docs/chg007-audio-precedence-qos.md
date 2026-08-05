# CHG-007 — Audio precedence + Rock EQ (83te)

**Session:** 7 · **Home chapter:** [VII](../README.md#chapter-vii--sound-that-knows-its-place)  
**CHG log:** [chronological ledger](../README.md#chg-log)  
**Host:** `83te` — Lenovo Yoga 7 2-in-1 16IPH11 (Omarchy / Arch, PipeWire + WirePlumber)  
**Date:** 2026-07-19  
**Status:** Applied  
**Later (same chapter):** [CHG-010](chg010-aux-desk-headset.md) inserts desk AUX and corrects the sof pro-audio map.

**Network note:** Meet / Zoom / Teams already marked **EF (DSCP 46)** on the LAN. This change does **not** install host nftables/CAKE.

---

## Summary

| Phase | What |
|-------|------|
| **1 — Precedence** | Output: soundcore P30i → Lenovo USB-C → built-in speakers. Input walks the same order among available mics (camera last). |
| **2 — App path** | Spotify + Google Chrome → Rock EQ → best hardware sink. Call mics use precedence. No host DSCP. |

### Decisions locked

1. Mic walks full input precedence among **available** sources  
2. Rock EQ always-on for music path  
3. Google Chrome only (no PWA friction)  
4. No host DSCP — network already has EF  

---

## Device order (Session 7 as applied)

| Priority | Output (sink) | Input (source) |
|----------|---------------|----------------|
| 1 | soundcore P30i (BT A2DP) | soundcore P30i mic (HFP only; A2DP has no capture) |
| 2 | Lenovo USB-C Wired In-Ear | Lenovo USB-C mic |
| 3 | Built-in speakers | Built-in dmic |
| last | — | USB camera mic |

> **Current desk order:** see [CHG-010](chg010-aux-desk-headset.md) — P30i → Lenovo → **AUX** → built-in → camera.

### App audio

| App | Behavior |
|-----|----------|
| Spotify | Rock EQ (`effect_input.eq`) |
| Google Chrome (YouTube TV, Meet tabs, etc.) | Rock EQ |
| Meet / Zoom / Teams | Best mic via precedence; media EF on network |
| EQ default | **Rock** always-on (`filter-chain.service`) |

---

## Layout in this repo

```
omarchy/
├── README.md
├── docs/chg007-audio-precedence-qos.md   # this file
├── docs/chg010-aux-desk-headset.md       # Session 10 extension
├── bin/
│   ├── audio-precedence-follow
│   └── audio-precedence-watch
├── config/
│   ├── audio-eq/{rock,edm}.conf
│   ├── systemd/user/audio-precedence-watch.service
│   └── wireplumber/wireplumber.conf.d/
│       ├── 50-device-precedence.conf
│       ├── 51-bluetooth-quality.conf
│       ├── 52-stream-music-eq.conf
│       └── bluetooth-a2dp-autoconnect.conf
└── scripts/
    ├── chg007-apply.sh / chg007-verify.fish / chg007-backout.sh
    └── chg010-apply.sh / chg010-verify.fish   # Session 10 entry points
```

---

## Apply

Prefer **CHG-010** entry points when installing the current (post-AUX) tree:

```fish
bash ~/Development/Projects/socfoundry/omarchy/scripts/chg010-apply.sh
fish ~/Development/Projects/socfoundry/omarchy/scripts/chg010-verify.fish
```

Historical Session 7 installer (same files; backup tag `chg007`):

```fish
bash ~/Development/Projects/socfoundry/omarchy/scripts/chg007-apply.sh
fish ~/Development/Projects/socfoundry/omarchy/scripts/chg007-verify.fish
```

What apply does:

1. Backs up `~/.config/wireplumber/wireplumber.conf.d`, `~/.config/audio-eq`, and filter-chain drop-ins to `*.bak.<tag>.<timestamp>`  
2. Installs WirePlumber + EQ configs and helpers into `~/.local/bin`  
3. Clears sticky `sof_sdw=off` profile state  
4. Sets default configured sink to `effect_input.eq`  
5. Enables/restarts `filter-chain` (Rock), `wireplumber`, `audio-precedence-watch`

### Runtime model

```
Spotify / Chrome
       │
       ▼
 effect_input.eq   (Rock / optional EDM via SUPER+CTRL+E)
       │
       ▼
 effect_output.eq  ──follow──► best hardware sink
                               (P30i → Lenovo → [AUX · CHG-010] → built-in)

Meet/Zoom/Teams capture ──► best source
                               (P30i HFP → Lenovo → [AUX] → dmic → camera)
```

`audio-precedence-watch` runs `pactl subscribe` and re-glues EQ output + default source when devices change.

### Hotkeys

| Key | Action |
|-----|--------|
| `SUPER+CTRL+E` | Cycle EQ: rock → edm → off |
| `SUPER+CTRL+SHIFT+E` | EQ status |

---

## Backout / revert

Prefer the automated script. It restores the newest `*.bak.chg010.*` / `*.bak.chg007.*` trees when present.

### Option A — Automated full backout (recommended)

```fish
bash ~/Development/Projects/socfoundry/omarchy/scripts/chg007-backout.sh
```

This will:

1. Disable and stop `audio-precedence-watch.service`  
2. Stop and disable `filter-chain.service`; remove EQ drop-in link  
3. Restore `~/.config/wireplumber/wireplumber.conf.d` from newest bak (or delete only CHG files if no bak)  
4. Restore `~/.config/audio-eq` and filter-chain conf.d from bak when available  
5. Remove `~/.local/bin/audio-precedence-{follow,watch}`  
6. Restore `~/.local/bin/audio-eq` from bak if present  
7. Remove the user systemd unit and reload  
8. Restore `default-profile` bak if present; clear `effect_input.eq` from default-nodes  
9. Restart WirePlumber and set default sink/source to live hardware  

Before overwriting live trees, backout copies the current state to `*.pre-backout.<timestamp>`.

### Option B — Soft backout (EQ + watcher only)

```fish
bash ~/Development/Projects/socfoundry/omarchy/scripts/chg007-backout.sh --soft
```

### Re-apply after backout

```fish
bash ~/Development/Projects/socfoundry/omarchy/scripts/chg010-apply.sh
fish ~/Development/Projects/socfoundry/omarchy/scripts/chg010-verify.fish
```

---

## Verify (post-apply)

```fish
fish ~/Development/Projects/socfoundry/omarchy/scripts/chg010-verify.fish
~/.local/bin/audio-precedence-follow --print
pw-link -l | rg 'eq|spotify|bluez'
```

Expected healthy path with P30i connected:

```
Spotify → effect_input.eq (Rock) → bluez_output.…P30i
default source → Lenovo USB-C mic (A2DP has no capture)
```
